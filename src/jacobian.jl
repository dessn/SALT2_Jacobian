using GZip
using FITSIO 
include("./surface.jl")

struct jacobian
    names
    trainopts
    spline_1
    spline_2
    colour_law
end

function jacobian(surfaces)
    base_colour_law = surfaces.base_colour_law
    colour_laws = surfaces.colour_laws
    base_spline = surfaces.base_spline
    splines = surfaces.splines

    names = surfaces.names

    trainopts = Dict(surfaces.trainopts[i] => surfaces.offsets[i] for i in 1:length(surfaces.trainopts))

    spline_1 = Dict(surfaces.trainopts[i] => spl.components[1].values - base_spline.components[1].values for (i, spl) in enumerate(splines))
    spline_2 = Dict(surfaces.trainopts[i] => spl.components[2].values - base_spline.components[2].values for (i, spl) in enumerate(splines))
    colour_law = Dict(surfaces.trainopts[i] => c.a - base_colour_law.a for (i, c) in enumerate(colour_laws))
    return jacobian(names, trainopts, spline_1, spline_2, colour_law)
end

function save_jacobian(jacobian, fname=nothing)
    if isnothing(fname)
        fname = joinpath(@__DIR__, "jacobian.fits.gz")
    end
    names = jacobian.names
    trainopts = jacobian.trainopts
    spline_1 = collect(values(jacobian.spline_1))
    spline_2 = collect(values(jacobian.spline_2))
    colour_law = collect(values(jacobian.colour_law))
    cols = [[spline_1[i]; spline_2[i]; colour_law[i]] for i in 1:length(spline_1)]
    data = hcat(cols...)
    data = collect(data')
    
    FITS(fname, "w") do io
        write(io, data)
    end
    
    FITS(fname, "r") do io
        global header
        header = read_header(io[1])
    end

    for (i, (k, v)) in enumerate(trainopts)
        header[string(names[i])] = string(join([k, v], " "))
    end

    FITS(fname, "w") do io
        write(io, data; header=header)
    end
end

function load_jacobian(fname=nothing)
    if isnothing(fname)
        fname = joinpath(@__DIR__, "jacobian.fits.gz")
    end
    FITS(fname, "r") do io
        global header
        global data
        header = read_header(io[1])
        data = read(io[1])
    end
    names = [key for key in keys(header) if occursin("TRAINOPT", key)]
    trainopts = Dict(join(split(header[key])[1:end-1], " ") => split(header[key])[end] for key in names)
    splines_1 = Dict(key => data[:, 1:1400][i, :] for (i, (key, value)) in enumerate(trainopts))
    splines_2 = Dict(key => data[:, 1401:2800][i, :] for (i, (key, value)) in enumerate(trainopts))
    colour_law = Dict(key => data[:, 2801:2804][i, :] for (i, (key, value)) in enumerate(trainopts))
    return jacobian(names, trainopts, splines_1, splines_2, colour_law)
end

