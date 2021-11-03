using ArgParse
using ProgressBars
include("./jacobian.jl")
include("./surface.jl")
include("./tools.jl")

function train_surface(input_trainopts, base_surface, jac, outdir)
    base_spline_1 = base_surface.spline.components[1].values
    base_spline_2 = base_surface.spline.components[2].values
    base_colour_law = base_surface.colour_law.a
    
    for (i, trainopt) in enumerate(input_trainopts)
        spline_1_offset = zeros(length(base_spline_1))
        spline_2_offset = zeros(length(base_spline_2))
        colour_law_offset = zeros(length(base_colour_law))
        for (opt, offset) in trainopt
            offset = parse(Float64, offset)
            j_offset = jac.trainopts[opt]
            j_offset = parse(Float64, j_offset)
            j_spline_1 = jac.spline_1[opt]
            j_spline_2 = jac.spline_2[opt]
            j_colour_law = jac.colour_law[opt]
            spline_1_offset += j_spline_1 .* (offset / j_offset)
            spline_2_offset += j_spline_2 .* (offset / j_offset)
            colour_law_offset += j_colour_law .* (offset / j_offset)
        end
        new_spline_1 = base_spline_1 + spline_1_offset
        new_spline_2 = base_spline_2 + spline_2_offset
        new_colour_law = base_colour_law + colour_law_offset

        destination_dir = joinpath(outdir, "TRAINOPT$(lpad(i,3,"0")).tar.gz")
        trainopt_dir_orig = uncompress(joinpath(outdir, "TRAINOPT000.tar.gz"))
        trainopt_dir = trainopt_dir_orig
        trainopt_dir = trainopt_dir[1: end-3] * lpad(i, 3, "0")
        mv(trainopt_dir_orig, trainopt_dir)

        spline_file = joinpath(trainopt_dir, "pca_1_opt1_final.list.gz")
        open(GzipDecompressorStream, spline_file) do io
            new_spline_file = readlines(io)
        end

        new_spline_file[2] = join(vcat(split(new_spline_file[2])[1:7], new_spline_1), " ")
        new_spline_file[3] = join(vcat(split(new_spline_file[3])[1:7], new_spline_2), " ")
        new_spline_file[end-8:end-5] = [string(a) for a in new_colour_law]
        new_spline_file = join(new_spline_file, "\n")

        open(GzipCompressorStream, spline_file, "w") do io
            write(io, new_spline_file)
        end

        colour_law_file = joinpath(trainopt_dir, "salt2_color_correction.dat.gz")
        open(GzipDecompressorStream, colour_law_file) do io
            new_colour_law_file = readlines(io)
        end
        
        new_colour_law_file[2:5] = [string(a) for a in new_colour_law]
        new_colour_law_file = join(new_colour_law_file, "\n")

        open(GzipCompressorStream, colour_law_file, "w") do io
            write(io, new_colour_law_file)
        end

        trainopt_dir = join(split(trainopt_dir, "/")[1:end-1], "/")
        compress(trainopt_dir, destination_dir) 
    end
end
        
function parse_input_file(input_file)
    open(input_file, "r") do io
        global raw 
        raw = readlines(io)
    end
    outdir = split([line for line in raw if occursin("OUTDIR", line)][1])[end]
    #trainopts = vcat([line for line in raw if occursin("MAGSHIFT", line)], [line for line in raw if occursin("WAVESHIFT", line)])
    trainopts = [line for line in raw if occursin("SHIFT", line)]
    trainopts = [split(line, "#")[1] for line in trainopts]
    trainopts = [split(line)[2:end] for line in trainopts]
    trainopts = [process_trainopts(line) for line in trainopts]
    return trainopts, outdir
end

function process_trainopts(opt)
    mag_eq = ["CfA3_STANDARD", "Calan/Tololo", "Other"]
    wave_eq = ["CfA3_STANDARD", "Calan/Tololo", "Other", "CfA2", "CfA1"]
    chunk(arr, n) = [arr[i:min(i + n - 1, end)] for i in 1:n:length(arr)] # Splits arr into n 
    opt_sets = chunk(opt, 4)
    rtn = Dict()
    for opt in opt_sets
        is_mag = opt[1] == "MAGSHIFT"
        if is_mag
            eq = mag_eq
        else
            eq = wave_eq
        end
        if opt[2] in eq
            opt[2] = eq[1]
            opt[3] = uppercase(opt[3])
        end
        opt3 = split(opt[3], ',')
        opt4 = split(opt[4], ',')
        for i in 1:length(opt3)
            rtn["$(opt[1]) $(opt[2]) $(opt3[i])"] = opt4[i]
        end
    end
    return rtn
end

function parse_cli()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--jacobian", "-j"
            help = "Path to jacobian file"
            default = nothing
        "--base" "-b"
            help = "Path to base surface directory"
            default = nothing
        "input"
            help = "Path to input file"
            required = true
    end

    return parse_args(s)
end

function main(parsed_args)
    base_dir = @__DIR__
    jacobian_path = parsed_args["jacobian"]
    if isnothing(jacobian_path)
        jacobian_path = joinpath(base_dir, "jacobian.fits.gz")
    end
    jac = load_jacobian(jacobian_path)
    base_surface_path = parsed_args["base"]
    if isnothing(base_surface_path)
        base_surface_path = joinpath(base_dir, "TRAINOPT000.tar.gz")
    end
    base_surface = surface("TRAINOPT000", "", base_surface_path)
    input_file = parsed_args["input"]
    trainopts, outdir = parse_input_file(input_file)
    @show outdir
    # DO BETTER THEN AUTO REMOVE
    rm(outdir, force=true, recursive=true)
    mkdir(outdir)
    cp(base_surface_path, joinpath(outdir, "TRAINOPT000.tar.gz"))

    train_surface(trainopts, base_surface, jac, outdir)
end

if !isinteractive()
    parsed_args = parse_cli()
    main(parsed_args)
end
