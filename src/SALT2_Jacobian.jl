module SALT2_Jacobian

# External Packages
using ArgParse
using OLUtils
using TOML
using Pkg

# Internal Packages
include("RunModule.jl")
using .RunModule: process_jacobian
include("RunBatchModule.jl")
using .RunBatchModule: process_jacobian as batch_process_jacobian

# Exports
export main

Base.@ccallable function julia_main()::Cint
    try
        main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function get_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--verbose", "-v"
            help = "Increase level of logging verbosity"
            action = :store_true
        "--jacobian", "-j"
            help = "Path to pretrained jacobian matrix"
            default = nothing 
        "--base", "-b"
            help = "Path to base (unperturbed) surface)"
            default = nothing 
        "--output", "-o"
            help = "Path to output directory, in which everything will be saved"
            default = nothing
        "--yaml", "-y"
            help = "Path to output yaml file. Will create a .yaml file, to be SNANA compliant"
            default = nothing
        "--trainopt", "-t"
            help = "TRAINOPT string, as used by submit_batch"
            default = nothing
        "--batch"
            help = "Whether or not we're running in batch mode. This changes a few options here and there."
            action = :store_true
        "input"
            help = "Path to .toml file. When given, all other options are ignored, expect for -v"
            default = nothing
    end

    return parse_args(s)
end

function main()
    Pkg.instantiate()
    args = get_args()
    verbose = args["verbose"]
    yaml_path = args["yaml"]
    batch_mode = args["batch"]
    try
        if !isnothing(args["input"])
            toml_path = args["input"]
            toml = TOML.parsefile(abspath(toml_path))
            if !("global" in keys(toml))
                toml["global"] = Dict()
            end
            toml["global"]["toml_path"] = dirname(abspath(toml_path))
        # Otherwise, we build our own dictionary from the given parameters
        else
            logging = !batch_mode 
            jacobian_path = args["jacobian"]
            if isnothing(jacobian_path)
                error("You must specify a jacobian path via --jacobian/-j if running from the command line (or from submit_batch)")
            end
            base_surface = args["base"]
            if isnothing(base_surface)
                error("You must specify a base surface via --base/-b if running from the command line (or from submit_batch)")
            end
            output_path = args["output"]
            if isnothing(output_path)
                error("You must specify an output directory via --output/-o if running from the command line (or from submit_batch)")
            end
            trainopt = args["trainopt"]
            if isnothing(trainopt)
                error("You must specify a trainopt via --trainopt/-t if running from the command line (or from submit_batch)")
            end
            global_dict = Dict("base_path" => "./", "output_path" => output_path, "logging" => logging, "toml_path" => "./")
            jacobian = Dict("path" => jacobian_path)
            surfaces = Dict("trainopts" => trainopt, "base_surface" => base_surface)
            toml = Dict("global" => global_dict, "jacobian" => jacobian, "surfaces" => surfaces)
        end
        setup_global!(toml, verbose)
        if batch_mode
            num_trainopts = batch_process_jacobian(toml)
        else
            num_trainopts = process_jacobian(toml)
        end
        if !isnothing(yaml_path)
            open(yaml_path, "w") do io
                write(io, "ABORT_IF_ZERO: 1\nNUM_TRAINOPTS: $num_trainopts")
            end
        end
    catch e
        if !isnothing(yaml_path)
            open(yaml_path, "w") do io
                write(io, "ABORT_IF_ZERO: 0\nERROR: $e")
            end
        end
        throw(e)
    end

end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
