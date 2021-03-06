module RunModule


# This modules runs the full SALT_Jacobian, including building jacobian matrices, comparing surfaces, and plotting 

# External Packages
using Statistics
using PrettyTables

# Internal Packages
include("Tools.jl")
using .Tools
include("SurfaceModule.jl")
using .SurfaceModule
include("JacobianModule.jl")
using .JacobianModule
include("Train.jl")
using .Train
include("Compare.jl")
using .Compare
include("Plot.jl")
using .Plot

# Exports
export process_jacobian

function jacobian_stage(toml, config)
    @info "Generating Jacobian"
    trained_surfaces = get(toml, "trained_surfaces", nothing)
    jacobian_path = get(toml, "path", nothing)
    # We are training a new jacobian
    if !isnothing(trained_surfaces)
        if !isabspath(trained_surfaces) 
            trained_surfaces = joinpath(config["base_path"], trained_surfaces)
        end
        trained_surfaces = abspath(trained_surfaces)
        @info "Training jacobian from $trained_surfaces"
        jacobian = Jacobian(trained_surfaces) 
        name = get(toml, "name", "jacobian")
        save_path = joinpath(config["output_path"], "$name.fits")
        @info "Saving to $save_path"
        save_jacobian(jacobian, save_path)
    elseif !isnothing(jacobian_path)
        if !isabspath(jacobian_path)
            jacobian_path = joinpath(config["base_path"], jacobian_path)
        end
        jacobian_path = abspath(jacobian_path)
        @info "Loading jacobian from $jacobian_path"
        jacobian = load_jacobian(jacobian_path)
    else
        @error "You must specify either a directory containing pretrained surfaces (via trained_surfaces = path) or a pretrained jacobian matrix (via path = path)"
        return nothing
    end
    return jacobian
end

function surfaces_stage(toml, config, jacobian)
    @info "Approximating Surfaces"
    base_surface_path = toml["base_surface"]
    if !isabspath(base_surface_path)
        base_surface_path = joinpath(config["base_path"], base_surface_path)
    end
    input_trainopts = ensure_list(toml["trainopts"])
    train_surfaces(input_trainopts, base_surface_path, jacobian, config["output_path"], false)
end

function comparison_stage(toml, config)
    @info "Comparing surfaces"
    comparison_path_1 = toml["comparison_path"]
    if !isabspath(comparison_path_1)
        comparison_path_1 = joinpath(config["base_path"], comparison_path_1)
    end
    comparison_surfaces_1 = ensure_list(get(toml, "comparison_surfaces", nothing))
    if isnothing(comparison_surfaces_1[1])
        comparison_surfaces_1 = [f for f in readdir(comparison_path_1, join=true) if !isnothing(match(r".*TRAINOPT.*\.tar\.gz", f))]
    else
        comparison_surfaces_1 = [joinpath(comparison_path_1, p) for p in comparison_surfaces_1]
    end
    comparison_name_1 = get(toml, "comparison_name", "SALT2 Trained Surfaces")
    if "surfaces" in keys(toml)
        comparison_path_2 = config["output_path"]
        comparison_surfaces_2 = [f for f in readdir(comparison_path_2, join=true) if !isnothing(match(r".*TRAINOPT.*\.tar\.gz", f))]
    elseif "comparison_path_2" in keys(toml)
        comparison_path_2 = toml["comparison_path_2"]
        if !isabspath(comparison_path_2)
            comparison_path_2 = joinpath(config["base_path"], comparison_path_2)
        end
        comparison_surfaces_2 = ensure_list(get(toml, "comparison_surfaces_2", nothing))
        if isnothing(comparison_surfaces_2[1])
            comparison_surfaces_2 = [f for f in readdir(comparison_path_2, join=true) if !isnothing(match(r".*TRAINOPT.*\.tar\.gz", f))]
        else
            comparison_surfaces_2 = [joinpath(comparison_path_2, p) for p in comparison_surfaces_2]
        end
    else
        @error "If you wish to compare surfaces without generating new ones, you must specify comparison_path_2. Otherwise you must generate surfaces via [ surfaces ]"
    end
    comparison_surfaces_2 = ensure_list(comparison_surfaces_2)
    comparison_name_2 = get(toml, "comparison_name_2", "Jacobian Trained Surfaces")
    strict_compare = get(toml, "strict_compare", true)
    summary = get(toml, "summary", true)
    comparison = compare_surfaces(comparison_surfaces_1, comparison_surfaces_2, strict_compare)
    if summary
        table = [[k[1], k[2], median(v[1]), median(v[2]), median(v[3])] for (k, v) in collect(comparison)]
    else
        table = [[k[1], k[2], v[1], v[2], v[3]] for (k, v) in collect(comparison)]
    end
    sort!(table, by=x->x[1]*x[2])

    if summary
        max_ind_s1 = argmax([t[3] for t in table])
        max_ind_s2 = argmax([t[4] for t in table])
        max_ind_cl = argmax([t[5] for t in table])
        med_s1 = median([t[3] for t in table])
        med_s2 = median([t[4] for t in table])
        med_cl = median([t[5] for t in table])
        
        prepend!(table, [
                 ["Median Percentage Difference", "", med_s1, med_s2, med_cl],
                 ["", "", "", "", ""],
                 ["Maximum Percentage Difference", "Spline 1", "", "", ""],
                 table[max_ind_s1],
                 ["Maximum Percentage Difference", "Spline 2", "", "", ""],
                 table[max_ind_s2],
                 ["Maximum Percentage Difference", "Colour Law", "", "", ""],
                 table[max_ind_cl],
                 ["", "", "", "", ""]
        ])
    end
    table = mapreduce(permutedims, vcat, table)
    pt = pretty_table(String, table, header = [comparison_name_1, comparison_name_2, "Spline 1", "Spline 2", "Colour Law"])
    @info "Comparison:\n$pt"
end

function plot_stage(plot_toml, config)
    for toml in plot_toml
        phase = get(toml, "phase", 0.0)
        @info "Plotting surfaces for phase $phase"
        plot_path = get(toml, "plot_path", config["output_path"])
        if !isabspath(plot_path)
            plot_path = joinpath(config["base_path"], plot_path)
        end
        plot_name = get(toml, "plot_name", "Surfaces_$(replace(string(phase), "."=>"_")).svg")
        save_path = joinpath(config["output_path"], plot_name)
        plot_surfaces = ensure_list(get(toml, "plot_surfaces", nothing))
        if isnothing(plot_surfaces[1])
            plot_surfaces = [f for f in readdir(plot_path, join=true) if !isnothing(match(r".*TRAINOPT.*\.tar\.gz", f))]
        else
            plot_surfaces = [joinpath(plot_path, p) for p in plot_surfaces]
        end
        plot_surfaces = [Surface(splitpath(p)[end], "", p) for p in plot_surfaces]
        fig, gax = plot_surface(plot_surfaces, phase)
        save_plot(save_path, fig)
        if "comparison_plot_path" in keys(toml)
            @info "Plotting residuals for phase $phase"
            comparison_plot_path = toml["comparison_plot_path"]
            if !isabspath(comparison_plot_path)
                comparison_plot_path = joinpath(config["base_path"], comparison_plot_path)
            end
            comparison_plot_name = get(toml, "comparison_plot_name", "Residuals_$(replace(string(phase), "."=>"_")).svg")
            comparison_save_path = joinpath(config["output_path"], comparison_plot_name)
            comparison_plot_surfaces = ensure_list(get(toml, "comparison_plot_surfaces", nothing))
            if isnothing(comparison_plot_surfaces[1])
                comparison_plot_surfaces = [f for f in readdir(comparison_plot_path, join=true) if !isnothing(match(r".*TRAINOPT.*\.tar\.gz", f))]
            else
                comparison_plot_surfaces = [joinpath(comparison_plot_path, p) for p in comparison_plot_surfaces]
            end
            comparison_plot_surfaces = [Surface(splitpath(p)[end], "", p) for p in comparison_plot_surfaces]
            strict_compare = get(toml, "strict_compare", true)
            fig, gax = plot_comparison(plot_surfaces, comparison_plot_surfaces, strict_compare, phase)
            save_plot(comparison_save_path, fig)
        end
    end
end

function process_jacobian(toml::Dict)
    config = toml["global"]
    num_trainopts = 0
    
    @debug "Base path: $(config["base_path"])"
    @debug "Output path: $(config["output_path"])"
    @info "Running with $(Threads.nthreads()) threads"

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

    # Compare surfaces
    if "compare" in keys(toml)
        if "surfaces" in keys(toml)
            toml["compare"]["surfaces"] = config["output_path"]
        end
        comparison_stage(toml["compare"], config)
    end

    if "plot" in keys(toml)
        plot_stage(toml["plot"], config)
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
