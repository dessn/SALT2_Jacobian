module RunBatchModule

# This modules runs SALT_Jacobian in batch mode. This changes how logging is performed, and improves performance as it doesn't both loading in the comparison and plotting stages.

# External Packages

# Internal Packages
include("Tools.jl")
using .Tools
include("SurfaceModule.jl")
using .SurfaceModule
include("JacobianModule.jl")
using .JacobianModule: load_jacobian
include("Train.jl")
using .Train

# Exports
export process_jacobian

function jacobian_stage(toml, config)
    @info "Generating Jacobian"
    trained_surfaces = get(toml, "trained_surfaces", nothing)
    jacobian_path = get(toml, "path", nothing)
    if isnothing(jacobian_path)
        @error "You must specify a pretrained jacobian matrix (via path = path)"
        return nothing
    end
    if !isabspath(jacobian_path)
        jacobian_path = joinpath(config["base_path"], jacobian_path)
    end
    jacobian_path = abspath(jacobian_path)
    @info "Loading jacobian from $jacobian_path"
    jacobian = load_jacobian(jacobian_path)
    return jacobian
end

function surfaces_stage(toml, config, jacobian)
    @info "Approximating Surfaces"
    base_surface_path = toml["base_surface"]
    if !isabspath(base_surface_path)
        base_surface_path = joinpath(config["base_path"], base_surface_path)
    end
    input_trainopts = ensure_list(toml["trainopts"])
    train_surfaces(input_trainopts, base_surface_path, jacobian, config["output_path"], true)
end

function process_jacobian(toml::Dict)
    config = toml["global"]
    num_trainopts = 0
    
    @debug "Base path: $(config["base_path"])"
    @debug "Output path: $(config["output_path"])"
    @info "Running with $(Threads.nthreads()) threads"
    @info "Running in Batch mode"

    # Create / load jacobian
    if "jacobian" in keys(toml)
        jacobian = jacobian_stage(toml["jacobian"], config)
    else
        jacobian = nothing
    end

    # Create approximate surfaces
    if "surfaces" in keys(toml)
        if isnothing(jacobian)
            @error "Can not approximate surfaces without a jacobian! Please define one via [ jacobian ]"
        end
        num_trainopts = surfaces_stage(toml["surfaces"], config, jacobian)
    end
    return num_trainopts
end

function process_jacobian(toml_path::AbstractString)
    toml = TOML.parsefile(toml_path)
    if !("global" in keys(toml))
        toml["global"] = Dict()
    end
    toml["global"]["toml_path"] = dirname(abspath(toml_path))
    return process_jacobian(toml)
end

end
