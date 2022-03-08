module Plot

# External Packages
using CairoMakie
CairoMakie.activate!(type = "svg")

# Internal Packages
using ..Tools
using ..SurfaceModule
using ..JacobianModule

# Exports
export plot_surface, plot_surface!
export plot_comparison, plot_comparison!
export save_plot

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

function plot_colour_law!(ax, surface::SurfaceModule.Surface)
    λ, A_λ, A_λ_σ_plus, A_λ_σ_minus = get_colour_law(surface)
    band!(ax, λ, A_λ_σ_plus, A_λ_σ_minus)
    lines!(ax, λ, A_λ)
end

function split_index(index, surface::SurfaceModule.Surface)
    index_phase = index % surface.spline.components[1].n_epochs
    index_wave = floor(index / surface.spline.components[1].n_epochs)
    return index_phase, index_wave
end

function phase_func(phase)
    return (-1.0 * (0.045 * phase) ^ 3 + phase + 6. * (1 / (1. + exp(-0.5 * (phase + 18))) + 1 / (1. + exp(-0.3 * (phase))) + 1 / (1. + exp(-0.3 * (phase - 20)))))
end

function reducedEpoch(phase_min, phase_max, phase)
    phase_func_min = phase_func(phase_min)
    phase_func_max = phase_func(phase_max)
    pedestal = 0
    number_of_parameters_for_phase = 14
    return ((phase_func(phase) - phase_func_min) / (phase_func_max - phase_func_min) * (number_of_parameters_for_phase) + pedestal)
end

function lambda_func(λ)
    return (1 / (1 + exp(-(λ - 4000) / 2000)))
end

function reducedLambda(λ_min, λ_max, λ)
    lambda_func_min = lambda_func(λ_min)
    lambda_func_max = lambda_func(λ_max)
    pedestal = 0
    number_of_parameters_for_lambda = 100
    return ((lambda_func(λ) - lambda_func_min) / (lambda_func_max - lambda_func_min) * (number_of_parameters_for_lambda) + pedestal)
end

function Bspline3(t, i)
    if (t < i) || (t > i+3)
        return 0
    elseif t < i + 1
        return 0.5 * (t-i)^2
    elseif t < i+2
        return 0.5 * ((i + 2 - t) * (t - i) + (t - i - 1) * (i + 3 - t))
    end
    return 0.5 * (i + 3 - t) ^ 2
end

function get_spline(surface::SurfaceModule.Surface, ind::Int64)
    n_points = surface.spline.components[ind].n_epochs * surface.spline.components[ind].n_wavelengths
    λ = collect(2000:10:9210)[1:end-1]
    flux = Float64[]
    for w in λ
        val = 0
        for i in 1:n_points
            index_phase, index_wave = split_index(i, surface)
            reduced_phase = reducedEpoch(surface.spline.components[1].phase_start, surface.spline.components[1].phase_end, 1.0)
            reduced_wave = reducedLambda(surface.spline.components[1].wave_start, surface.spline.components[1].wave_end, w)
            interp = Bspline3(reduced_phase, index_phase) * Bspline3(reduced_wave, index_wave)
            val += interp * surface.spline.components[1].values[i]
        end
        push!(flux, val)
    end
    return (λ, flux)
end

function plot_spline!(ax, surface::SurfaceModule.Surface, ind::Int64)
    λ, flux = get_spline(surface, ind)
    lines!(ax, λ, flux, label=surface.name)
end

function plot_surface!(gax, surface::SurfaceModule.Surface)
    ax_1, ax_2, ax_3 = gax
    plot_spline!(ax_1, surface, 1)
    plot_spline!(ax_2, surface, 2)
    plot_colour_law!(ax_3, surface)
end

function plot_surface(surface::SurfaceModule.Surface)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 1")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 2")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    plot_surface!([ax_1, ax_2, ax_3], surface)
    return fig, [ax_1, ax_2, ax_3]
end

function plot_surface(surfaces::Vector{SurfaceModule.Surface})
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 1")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 2")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    for surface in surfaces
        plot_surface!([ax_1, ax_2, ax_3], surface)
    end
    return fig, [ax_1, ax_2, ax_3]
end

function plot_comparison!(gax, surface1::SurfaceModule.Surface, surface2::SurfaceModule.Surface)
    ax_1, ax_2, ax_3 = gax
    λ1_1, flux1_1 = get_spline(surface1, 1)
    λ2_1, flux2_1 = get_spline(surface2, 1)
    s1 = @. flux2_1 - flux1_1
    lines!(ax_1, λ1_1, s1)
    λ1_2, flux1_2 = get_spline(surface1, 2)
    λ2_2, flux2_2 = get_spline(surface1, 2)
    s2 = @. flux2_2 - flux1_2
    lines!(ax_2, λ1_2, s2)
    λ1_c, A_λ1, A_λ1_σ_plus, A_λ1_σ_minus = get_colour_law(surface1)
    λ2_c, A_λ2, A_λ2_σ_plus, A_λ2_σ_minus = get_colour_law(surface2)
    c2 = @. A_λ2 - A_λ1
    c1_plus = @. c2 + ((A_λ1_σ_plus - A_λ1) + (A_λ2_σ_plus - A_λ2))
    c1_minus = @. c2 + ((A_λ1 - A_λ1_σ_minus) + (A_λ2 - A_λ2_σ_minus))
    #band!(ax_3, λ1_c, c1_plus, c1_minus) 
    lines!(ax_3, λ1_c, c2)
end

function plot_comparison(surface1::SurfaceModule.Surface, surface2::SurfaceModule.Surface, strict_compare::Bool)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 1")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 2")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    if (!strict_compare) | (strict_compare & (surface1.name == surface2.name))
        plot_comparison!([ax_1, ax_2, ax_3], surface1, surface2)
    end
end

function plot_comparison(surfaces1::Vector{SurfaceModule.Surface}, surfaces2::Vector{SurfaceModule.Surface}, strict_compare::Bool)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 1 residual")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "Spline 2 residual")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law resiudal")
    for surface1 in surfaces1
        for surface2 in surfaces2
            if (!strict_compare) | (strict_compare & (surface1.name == surface2.name))
                plot_comparison!([ax_1, ax_2, ax_3], surface1, surface2)
            end
        end
    end
    return fig, [ax_1, ax_2, ax_3]
end

function save_plot(path::AbstractString, fig::Figure)
    save(path, fig)
end

end
