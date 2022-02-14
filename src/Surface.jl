module Surface

# External Packages
using FITSIO 
using CodecZlib

# Internal packages
using ..Tools

struct colour_law
    a
end

function colour_law(raw::Vector{String})
    a1 = parse(Float64, raw[2])
    a2 = parse(Float64, raw[3])
    a3 = parse(Float64, raw[4])
    a4 = parse(Float64, raw[5])
    return colour_law([a1, a2, a3, a4])
end

struct colour_law_err
    λ
    σ
end

function colour_law_err(raw::Vector{String})
    lines = [line for line in raw if !occursin("#", line)]
    λ = [parse(Float64, split(line)[1]) for line in lines]
    σ = [parse(Float64, split(line)[2]) for line in lines]
    return colour_law_err(λ, σ)
end

struct spline
    n_components
    components
end

function spline(raw)
    n_components = parse(Int,raw[1])
    components = [component(split(raw[ind+1])) for ind in 1:n_components]
    return spline(n_components, components)
end

struct component
    basis
    n_epochs
    n_wavelengths
    phase_start
    phase_end
    wave_start
    wave_end
    values
end

function component(comp)
    basis = comp[1]
    n_epochs = parse(Int64, comp[2])
    n_wavelengths = parse(Int64, comp[3])
    phase_start = parse(Float64, comp[4])
    phase_end = parse(Float64, comp[5])
    wave_start = parse(Float64, comp[6])
    wave_end = parse(Float64, comp[7])
    values = map(x->parse(Float64, x), comp[8:end])
    return component(basis, n_epochs, n_wavelengths, phase_start, phase_end, wave_start, wave_end, values)
end

struct surface
    name
    trainopt
    colour_law
    colour_law_err
    spline
end

function surface(name, trainopt, surface_path::AbstractString)
    surface_path = uncompress(surface_path)

    colour_law_path = joinpath(surface_path, "salt2_color_correction.dat.gz")
    raw_colour_law = nothing
    open(GzipDecompressorStream, colour_law_path) do io
        raw_colour_law = readlines(io)
    end
    raw_colour_law = [line for line in raw_colour_law if length(split(line))!=0]
    c_law = colour_law(raw_colour_law)

    colour_law_err_path = joinpath(surface_path, "salt2_color_dispersion.dat.gz")
    raw_colour_law_err = nothing
    open(GzipDecompressorStream, colour_law_err_path) do io
        raw_colour_law_err = readlines(io)
    end
    raw_colour_law_err = [line for line in raw_colour_law_err if length(split(line))!=0]
    c_law_err = colour_law_err(raw_colour_law_err)

    spline_path = joinpath(surface_path, "pca_1_opt1_final.list.gz")
    raw_spline = nothing
    open(GzipDecompressorStream, spline_path) do io
        raw_spline = readlines(io)
    end
    raw_spline = [line for line in raw_spline if length(split(line))!=0]
    spl = spline(raw_spline)
    return surface(name, trainopt, c_law, c_law_err, spl)
end

end
