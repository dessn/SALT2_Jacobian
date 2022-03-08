module JacobianModule

# External Packages
using GZip
using FITSIO 

# Internal Packages
using ..SurfaceModule

# Exports
export Jacobian, load_jacobian, save_jacobian

# A collection of a base surface and a number of offset surfaces
struct Surfaces
    base_name
    names
    base_trainopt
    trainopts
    base_offset
    offsets
    base_colour_law
    colour_laws
    base_spline
    splines
end

function Surfaces(spline_directory::AbstractString)
    submit_info_path = joinpath(spline_directory, "SUBMIT.INFO")
    submit_info = readlines(submit_info_path)
    ind_start = findfirst(x->occursin("TRAINOPT_OUT_LIST", x), submit_info)
    ind_end = findfirst(x->occursin("CALIB_UPDATES:", x), submit_info)
    trainopts = [split(line[6:end-2], ", ") for line in submit_info[ind_start+1:ind_end-1] if length(line) != 0]
    opts = [opt[3][2:end-1] for opt in trainopts]
    file_names = [opt[1][2:end-1] * ".tar.gz" for opt in trainopts]
    all_surfaces = [Surface(n, opts[i], joinpath(spline_directory, n)) for (i, n) in enumerate(file_names)]
    
    base_name = file_names[1]
    names = file_names[2:end]
    base_trainopt = join(split(opts[1])[1:end-1], " ")
    trainopts = [join(split(opt)[1:end-1], " ") for opt in opts[2:end]]
    base_offset = "0.0" 
    offsets = [split(opt)[end] for opt in opts[2:end]]
    base_colour_law = all_surfaces[1].colour_law
    colour_laws = [s.colour_law for s in all_surfaces[2:end]]
    base_spline = all_surfaces[1].spline
    splines = [s.spline for s in all_surfaces[2:end]]
    return Surfaces(base_name, names, base_trainopt, trainopts, base_offset, offsets, base_colour_law, colour_laws, base_spline, splines)
end

# SALT2 Jacobian
struct Jacobian
    names
    trainopts
    offsets
    spline_1
    spline_2
    colour_law
end

function Jacobian(surfaces)
    base_colour_law = surfaces.base_colour_law
    colour_laws = surfaces.colour_laws
    base_spline = surfaces.base_spline
    splines = surfaces.splines

    names = surfaces.names

    trainopts = Dict(n => surfaces.trainopts[i] for (i, n) in enumerate(names)) 
    offsets = Dict(n => surfaces.offsets[i] for (i, n) in enumerate(names))

    spline_1 = Dict(names[i] => spl.components[1].values - base_spline.components[1].values for (i, spl) in enumerate(splines))
    spline_2 = Dict(names[i] => spl.components[2].values - base_spline.components[2].values for (i, spl) in enumerate(splines))
    colour_law = Dict(names[i] => c.a - base_colour_law.a for (i, c) in enumerate(colour_laws))
    return Jacobian(names, trainopts, offsets, spline_1, spline_2, colour_law)
end

function Jacobian(spline_directory::AbstractString)
    surfaces = Surfaces(spline_directory)
    return Jacobian(surfaces)
end

function save_jacobian(jacobian, fname)
    ind = sortperm(jacobian.names)
    names = jacobian.names[ind]

    spline_1 = [jacobian.spline_1[n] for n in names]
    spline_2 = [jacobian.spline_2[n] for n in names]
    colour_law = [jacobian.colour_law[n] for n in names]
    cols = [[spline_1[i]; spline_2[i]; colour_law[i]] for i in 1:length(spline_1)]
    data = hcat(cols...)
    data = collect(data')
    
    FITS(fname, "w") do io
        write(io, data)
    end
    
    # Open fits file again in order to correctly set new header keys
    header = FITS(fname, "r") do io
        return read_header(io[1])
    end

    for n in names
        header[string(n)] = string(join([jacobian.trainopts[n], jacobian.offsets[n]], " "))
    end

    FITS(fname, "w") do io
        write(io, data; header=header)
    end
end

function load_jacobian(fname=nothing)
    if isnothing(fname)
        fname = joinpath(@__DIR__, "jacobian.fits.gz")
    end
    header, data = FITS(fname, "r") do io
        return read_header(io[1]), read(io[1])
    end
    names = [key for key in keys(header) if occursin("TRAINOPT", key)]
    trainopts = Dict(n => join(split(header[n])[1:end-1], " ") for n in names)
    offsets = Dict(n => split(header[n])[end] for n in names)
    splines_1 = Dict(n => data[:, 1:1400][i, :] for (i, n) in enumerate(names))
    splines_2 = Dict(n => data[:, 1401:2800][i, :] for (i, n) in enumerate(names))
    colour_law = Dict(n => data[:, 2801:2804][i, :] for (i, n) in enumerate(names))
    return Jacobian(names, trainopts, offsets, splines_1, splines_2, colour_law)
end

end
