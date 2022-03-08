module SurfaceModule
# Describes a SALT2 surface

# External Packages
using FITSIO 
using CodecZlib

# Internal packages
using ..Tools

# Exports
export Surface

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
    basis
    n_epochs
    n_wavelengths
    phase_start
    phase_end
    wave_start
    wave_end
    values
end

function Component(comp)
    basis = comp[1]
    n_epochs = parse(Int64, comp[2])
    n_wavelengths = parse(Int64, comp[3])
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
    name
    trainopt
    colour_law
    colour_law_err
    spline
end

function Surface(name, trainopt, surface_path::AbstractString)
    surface_path = uncompress(surface_path)

    colour_law_path = joinpath(surface_path, "salt2_color_correction.dat.gz")
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

end
