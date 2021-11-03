using ArgParse
include("./jacobian.jl")
include("./surface.jl")

struct surfaces
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

function surfaces(spline_directory::AbstractString)

    submit_info_path = joinpath(spline_directory, "SUBMIT.INFO")
    
    submit_info = readlines(submit_info_path)
    
    ind_start = findfirst(x->occursin("TRAINOPT_OUT_LIST", x), submit_info)
    
    ind_end = findfirst(x->occursin("CALIB_UPDATES:", x), submit_info)
    
    trainopts = [split(line[6:end-2], ", ") for line in submit_info[ind_start+1:ind_end-1] if length(line) != 0]
    
    opts = [opt[3][2:end-1] for opt in trainopts]
    
    file_names = [opt[1][2:end-1] * ".tar.gz" for opt in trainopts]

    all_surfaces = [surface(n, opts[i], joinpath(spline_directory, n)) for (i, n) in enumerate(file_names)]
    
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
    return surfaces(base_name, names, base_trainopt, trainopts, base_offset, offsets, base_colour_law, colour_laws, base_spline, splines)
end
    
function parse_cli()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--jacobian", "-j"
            help = "Where to save the jacobian"
            default = nothing
        "OUTPUT_TRAIN"
            help = "Directory containing the SUBMIT.INFO and TRAINOPTxxx files / folders."
            required = true
    end

    return parse_args(s)
end

function main(parsed_args)
    dir = parsed_args["OUTPUT_TRAIN"]
    fname = parsed_args["jacobian"]
    sur = surfaces(dir)
    jac = jacobian(sur)
    save_jacobian(jac, fname)
end

if !isinteractive()
    parsed_args = parse_cli()
    main(parsed_args)
end
