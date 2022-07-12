module SurfaceModule
# Describes a SALT2 surface

# External Packages
using FITSIO 
using CodecZlib

# Internal packages
using ..Tools

# Exports
export Surface
export get_spline
export get_colour_law

struct ColourLaw
    a::Vector{Float64} # Colour law components
end

function ColourLaw(raw::Vector{String})
    a1 = parse(Float64, raw[2])
    a2 = parse(Float64, raw[3])
    a3 = parse(Float64, raw[4])
    a4 = parse(Float64, raw[5])
    return ColourLaw([a1, a2, a3, a4])
end

struct ColourLawErr
    λ::Vector{Float64} # Wavelength
    σ::Vector{Float64} # Uncertainty
end

function ColourLawErr(raw::Vector{String})
    lines = [line for line in raw if !occursin("#", line)]
    λ = [parse(Float64, split(line)[1]) for line in lines]
    σ = [parse(Float64, split(line)[2]) for line in lines]
    return ColourLawErr(λ, σ)
end

struct Component
    basis::String
    n_epochs::Float64
    n_wavelengths::Float64
    phase_start::Float64
    phase_end::Float64
    wave_start::Float64
    wave_end::Float64
    values::Vector{Float64}
end

function Component(comp)
    basis = comp[1]
    n_epochs = parse(Float64, comp[2])
    n_wavelengths = parse(Float64, comp[3])
    phase_start = parse(Float64, comp[4])
    phase_end = parse(Float64, comp[5])
    wave_start = parse(Float64, comp[6])
    wave_end = parse(Float64, comp[7])
    values = map(x->parse(Float64, x), comp[8:end])
    return Component(basis, n_epochs, n_wavelengths, phase_start, phase_end, wave_start, wave_end, values)
end

struct Spline
    n_components::Int64
    components::Vector{Component}
end

function Spline(raw)
    n_components = parse(Int,raw[1])
    components = [Component(split(raw[ind+1])) for ind in 1:n_components]
    return Spline(n_components, components)
end

struct Surface
    name::String
    trainopt::String
    colour_law::ColourLaw
    colour_law_err::ColourLawErr
    spline::Spline
end

function Surface(name, trainopt, surface_path::AbstractString)
    surface_path = uncompress(surface_path)

    colour_law_path = joinpath(surface_path, "salt2_color_correction_final.dat.gz")
    raw_colour_law = open(GzipDecompressorStream, colour_law_path) do io
        return readlines(io)
    end
    raw_colour_law = [line for line in raw_colour_law if length(split(line))!=0]
    c_law = ColourLaw(raw_colour_law)

    colour_law_err_path = joinpath(surface_path, "salt2_color_dispersion.dat.gz")
    raw_colour_law_err = open(GzipDecompressorStream, colour_law_err_path) do io
        return readlines(io)
    end
    raw_colour_law_err = [line for line in raw_colour_law_err if length(split(line))!=0]
    c_law_err = ColourLawErr(raw_colour_law_err)

    spline_path = joinpath(surface_path, "pca_1_opt1_final.list.gz")
    raw_spline = open(GzipDecompressorStream, spline_path) do io
        return readlines(io)
    end
    raw_spline = [line for line in raw_spline if length(split(line))!=0]
    spl = Spline(raw_spline)
    return Surface(name, trainopt, c_law, c_law_err, spl)
end

function reduced_lambda(λ)
    wave_B = 4302.57
    wave_V = 5428.55
    return @. (λ-wave_B) / (wave_V - wave_B)
end

function derivative(α, surface, r_λ)
    for (e, a) in enumerate(surface.colour_law.a)
        α += (e + 1) * a * (r_λ ^ e)
    end
    return α
end

function c_law(α, surface, r_λ)
    d = α * r_λ
    for (e, a) in enumerate(surface.colour_law.a)
        d += a * (r_λ ^ (e + 1))
    end
    return d
end

function get_colour_law(surface::SurfaceModule.Surface)
    constant = 0.4 * log(10)
    λ_min = 2800
    λ_max = 7000
    r_λ_min = reduced_lambda(λ_min)
    r_λ_max = reduced_lambda(λ_max)

    λ = collect(λ_min:λ_max)
    r_λ = reduced_lambda(λ)

    α = 1

    for a in surface.colour_law.a
        α -= a
    end

    p_derivative_min = derivative(α, surface, r_λ_min)
    p_derivative_max = derivative(α, surface, r_λ_max)

    p_r_λ_min = c_law(α, surface, r_λ_min)
    p_r_λ_max = c_law(α, surface, r_λ_max)

    λ = collect(2000:10:9210)[1:end-1]
    r_λ = reduced_lambda(λ)
    p = zeros(length(r_λ))

    for (i, r) in enumerate(r_λ)
        if r < r_λ_min
            p[i] = @. p_r_λ_min + p_derivative_min * (r - r_λ_min)
        elseif r > r_λ_max
            p[i] = @. p_r_λ_max + p_derivative_max * (r - r_λ_max)
        else
            p[i] = c_law(α, surface, r)
        end
    end

    C = 0.1

    A_λ = @. -p * C * constant
    A_λ_σ_plus = @. -(p + surface.colour_law_err.σ) * C * constant
    A_λ_σ_minus = @. -(p - surface.colour_law_err.σ) * C * constant
    return (λ, A_λ, A_λ_σ_plus, A_λ_σ_minus)
end

function split_index(index, surface::SurfaceModule.Surface)
    n_epochs::Float64 = surface.spline.components[1].n_epochs
    index_phase::Float64 = index % n_epochs 
    index_wave::Float64 = floor(index / n_epochs)
    return index_phase, index_wave
end

function phase_func(phase)
    return (-1.0 * (0.045 * phase) ^ 3.0 + phase + 6.0 * (1.0 / (1.0 + exp(-0.5 * (phase + 18.0))) + 1.0 / (1.0 + exp(-0.3 * (phase))) + 1.0 / (1.0 + exp(-0.3 * (phase - 20.0)))))
end

function reducedEpoch(phase_min, phase_max, phase)
    phase_func_min = phase_func(phase_min)
    phase_func_max = phase_func(phase_max)
    number_of_parameters_for_phase = 14.0
    return number_of_parameters_for_phase * (phase_func(phase) - phase_func_min) / (phase_func_max - phase_func_min)
end

function lambda_func(λ)
    return (1.0 / (1.0 + exp(-(λ - 4000.0) / 2000.0)))
end

function reducedLambda(lambda_func_min, lambda_func_max, λ)
    number_of_parameters_for_lambda = 100.0
    return number_of_parameters_for_lambda * (lambda_func(λ) - lambda_func_min) / (lambda_func_max - lambda_func_min)
end

function Bspline3(t, i)
    if (t < i) || (t > i + 3.0)
        return 0.0
    elseif t < i + 1.0
        return 0.5 * (t-i)^2.0
    elseif t < i+2.0
        return 0.5 * ((i + 2.0 - t) * (t - i) + (t - i - 1.0) * (i + 3.0 - t))
    end
    return 0.5 * (i + 3.0 - t) ^ 2.0
end

function get_spline(surface::SurfaceModule.Surface, component::Int64, phase::Float64)
    components = surface.spline.components[component]
    lambda_func_min = lambda_func(components.wave_start)
    lambda_func_max = lambda_func(components.wave_end)
    reduced_phase = reducedEpoch(components.phase_start, components.phase_end, phase)
    n_points::Int64 = components.n_epochs * components.n_wavelengths
    λ = collect(2000:5:9200)
    if phase <= -20.0
        flux = zeros(length(λ))
    else
        flux = Vector{Float64}(undef, length(λ))
        for (i, w) in enumerate(λ)
            reduced_wave = reducedLambda(lambda_func_min, lambda_func_max, w)
            flux_val = 0.0
            @simd for j in 1:n_points
                index_phase, index_wave = split_index(j, surface)
                interp = Bspline3(reduced_phase, index_phase) * Bspline3(reduced_wave, index_wave)
                @inbounds flux_val += interp * components.values[j]
            end
            #if abs(flux_val) <= 1e-25
            #    flux_val = 0.0
            #end
            flux[i] = flux_val
        end
    end
    return (λ, flux)
end

end
