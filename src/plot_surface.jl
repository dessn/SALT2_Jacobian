using ArgParse
using CairoMakie
include("./jacobian.jl")
include("./surface.jl")
include("./tools.jl")

function parse_cli()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--strict_compare", "-c"
            help = "If includes, only compare surfaces with the same TRAINOPT id (I.e TRAINOPT000 to TRAINOPT000 and TRAINOPT001 to TRAINOPT001). Only works if both surface_1 and surface_2 point to multiple surfaces"
            action = :store_true
        "--path", "-p"
            help = "Path to where plots should be saved"
            default = "."
        "--name", "-n"
            help = "Default name of plot, if multiple plots, name will be name_i.pdf where i is the number of the plot"
            default = "Surface"
        "--surface_2", "-s"
            help = "Should point to either the TRAINOPTxxx file which contans pca_1_opt1_final.list.gz and salt2_colour_correction.data.gz, or a directory which contains the TRAINOPTs"
            default = nothing
        "surface_1"
            help = "Should point to either the TRAINOPTxxx file which contans pca_1_opt1_final.list.gz and salt2_colour_correction.data.gz, or a directory which contains the TRAINOPTs"
            required = true
    end
    return parse_args(s)
end

function setup_fig(surface_1::surface, surface_2::surface, strict_compare)
    fig = Figure(title="$(surface_1.name) & $(surface_2.name)")
    ax1 = Axis(fig[2, 1], ylabel="Flux")
    ax2 = Axis(fig[3, 1], xlabel="Wavelength (Å)", ylabel="-1×c×CL(λ) or A(λ)-A(B)\nfor E(B-V)=0.1")
    linkxaxes!(ax1, ax2)
    return fig, ax1, ax2, surface_1, surface_2
end

function setup_fig(surface_1::surface, surface_2::Nothing, strict_compare)
    fig = Figure(title=surface_1.name)
    ax1 = Axis(fig[2, 1], ylabel="Flux")
    ax2 = Axis(fig[3, 1], xlabel="Wavelength (Å)", ylabel="-1×c×CL(λ) or A(λ)-A(B)\nfor E(B-V)=0.1")
    linkxaxes!(ax1, ax2)

    return fig, ax1, ax2, surface_1, surface_2
end

function setup_fig(surface_1, surface_2::Nothing, strict_compare)
    fig_list = []
    ax1_list = []
    ax2_list = []
    surface_1_list = []
    for surf in surface_1
        fig, ax1, ax2, s1, _ = setup_fig(surf, surface_2, strict_compare)
        push!(fig_list, fig)
        push!(ax1_list, ax1)
        push!(ax2_list, ax2)
        push!(surface_1_list, s1)
    end
    return fig_list, ax1_list, ax2_list, surface_1_list, surface_2
end

function setup_fig(surface_1::surface, surface_2, strict_compare)
    fig_list = []
    ax1_list = []
    ax2_list = []
    surface_2_list = []
    for surf in surface_2
        fig, ax1, ax2, _, s2 = setup_fig(surface_1, surf, strict_compare)
        push!(fig_list, fig)
        push!(ax1_list, ax1)
        push!(ax2_list, ax2)
        push!(surface_2_list, s2)
    end
    return fig_list, ax1_list, ax2_list, surface_1, surface_2_list
end

function setup_fig(surface_1, surface_2::surface, strict_compare)
    fig_list, ax1_list, ax2_list, surface_2, surface_1_list = setup_fig(surface_2, surface_1, strict_compare)
    return fig_list, ax1_list, ax2_list, surface_1_list, surface_2 
end

function setup_fig(surface_1, surface_2, strict_compare)
    fig_list = []
    ax1_list = []
    ax2_list = []
    surface_1_list = []
    surface_2_list = []
    for surf1 in surface_1
        for surf2 in surface_2
            if strict_compare && surf1.name != surf2.name 
                continue
            end
            fig, ax1, ax2, s1, s2 = setup_fig(surf1, surf2, strict_compare)
            push!(fig_list, fig)
            push!(ax1_list, ax1)
            push!(ax2_list, ax2)
            push!(surface_1_list, s1)
            push!(surface_2_list, s2)
        end
    end
    return fig_list, ax1_list, ax2_list, surface_1_list, surface_2_list
end

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

function plot_colour_law!(ax, surface::surface)
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
    band!(ax, λ, A_λ_σ_plus, A_λ_σ_minus)
    lines!(ax, λ, A_λ)
    return ax
end

function split_index(index, surface::surface)
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

function plot_spline!(ax, surface::surface)
    n_points = surface.spline.components[1].n_epochs * surface.spline.components[1].n_wavelengths
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
    lines!(ax, λ, flux, label=surface.name)
    return ax
end

function plot_surface!(ax1, ax2, surface_1::surface, surface_2::surface)
    ax1 = plot_spline!(ax1, surface_1)
    ax1 = plot_spline!(ax1, surface_2)
    ax2 = plot_colour_law!(ax2, surface_1)
    ax2 = plot_colour_law!(ax2, surface_2)
    return ax1, ax2
end

function plot_surface!(ax1, ax2, surface_1::surface, surface_2::Nothing)
    ax1 = plot_spline!(ax1, surface_1)
    ax2 = plot_colour_law!(ax2, surface_1)
    return ax1, ax2
end

function plot_surface!(ax1, ax2, surface_1, surface_2::Nothing)
    ax1_list = []
    ax2_list = []
    for (i, ax) in enumerate(ax1)
        push!(ax1_list, plot_spline!(ax, surface_1[i]))
    end
    for (i, ax) in enumerate(ax2)
        push!(ax2_list, plot_colour_law!(ax, surface_1[i]))
    end
    return ax1_list, ax2_list
end

function plot_surface!(ax1, ax2, surface_1, surface_2::surface)
    ax1_list = []
    ax2_list = []
    for (i, surf) in enumerate(surface_1)
        ax = ax1[i]
        ax = plot_spline!(ax, surf)
        ax = plot_spline!(ax, surface_2)
        push!(ax1_list, ax)
        ax = ax2[i]
        ax = plot_colour_law!(ax, surf)
        ax = plot_colour_law!(ax, surface_2)
        push!(ax2_list, ax)
    end
    return ax1_list, ax2_list
end

function plot_surface!(ax1, ax2, surface_1::surface, surface_2)
    return plot_surface!(ax1, ax2, surface_2, surface_1)
end

function plot_surface!(ax1, ax2, surface_1, surface_2)
    ax1_list = []
    ax2_list = []
    for (i, surf1) in enumerate(surface_1)
        ax = ax1[i]
        surf2 = surface_2[i]
        ax = plot_spline!(ax, surf1)
        ax = plot_spline!(ax, surf2)
        push!(ax1_list, ax)
        ax = ax2[i]
        ax = plot_colour_law!(ax, surf1)
        ax = plot_colour_law!(ax, surf2)
        push!(ax2_list, ax)
    end
    return ax1_list, ax2_list
end

function main(parsed_args)
    strict_compare = parsed_args["strict_compare"]
    surface_2_path = parsed_args["surface_2"]
    surface_1_path = parsed_args["surface_1"]
    path = parsed_args["path"]
    name = parsed_args["name"]
    if occursin("TRAINOPT", uppercase(surface_1_path))
        surface_1 = surface(String(surface_1_path), "_", surface_1_path)
    else
        surface_1 = [surface(String(split(path, "/")[end]), "_", joinpath(surface_1_path, path)) for path in readdir(surface_1_path) if occursin("TRAINOPT", uppercase(path))]
    end
    if !isnothing(surface_2_path)
        if occursin("TRAINOPT", uppercase(surface_2_path))
            surface_2 = surface(String(surface_2_path), "_", surface_2_path)
        else
            surface_2 = [surface(String(split(path, "/")[end]), "_", joinpath(surface_2_path, path)) for path in readdir(surface_2_path) if occursin("TRAINOPT", uppercase(path))]
        end
    else
        surface_2 = nothing
    end
    fig, ax1, ax2, surface_1, surface_2 = setup_fig(surface_1, surface_2, strict_compare)
    plot_surface!(ax1, ax2, surface_1, surface_2)
    is_list = false
    try
        ax1[1]
        is_list = true
    catch
    end
    if is_list
        @show [typeof(ax) for ax in ax1 if typeof(ax) != Axis]
        @show [typeof(f) for f in fig if typeof(f) != Figure]
        for (i, f) in enumerate(fig)
            f[1, 1] = Legend(f, ax1[i], "Surfaces", framevisible=false)
            save(joinpath(path, "$(name)_$i.pdf"), f)
        end
    else
        fig[1, 1] = Legend(fig, ax1, "Surfaces", framevisible=false) 
        save(joinpath(path, "$name.pdf"), fig)
    end
end

if !isinteractive()
    parsed_args = parse_cli()
    main(parsed_args)
end
