module Plot

# External Packages
using CairoMakie
CairoMakie.activate!(type = "svg")

# Internal Packages
using ..Tools
using ..SurfaceModule
using ..JacobianModule

# Exports
export plot_surface, plot_surface!
export plot_comparison, plot_comparison!
export save_plot

function plot_colour_law!(ax, surface::SurfaceModule.Surface)
    λ, A_λ, A_λ_σ_plus, A_λ_σ_minus = get_colour_law(surface)
    band!(ax, λ, A_λ_σ_plus, A_λ_σ_minus)
    lines!(ax, λ, A_λ)
end

function plot_spline!(ax, surface::SurfaceModule.Surface, ind::Int64, phase::Float64)
    λ, flux = get_spline(surface, ind, phase)
    lines!(ax, λ, flux, label=surface.name)
end

function plot_surface!(gax, surface::SurfaceModule.Surface, phase::Float64)
    ax_1, ax_2, ax_3 = gax
    plot_spline!(ax_1, surface, 1, phase)
    plot_spline!(ax_2, surface, 2, phase)
    plot_colour_law!(ax_3, surface)
end

function plot_surface(surface::SurfaceModule.Surface, phase::Float64)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M0 @ phase $phase")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M1 @ phase $phase")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    plot_surface!([ax_1, ax_2, ax_3], surface, phase)
    return fig, [ax_1, ax_2, ax_3]
end

function plot_surface(surfaces::Vector{SurfaceModule.Surface}, phase::Float64)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M0 @ phase $phase")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M1 @ phase $phase")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    for surface in surfaces
        plot_surface!([ax_1, ax_2, ax_3], surface, phase)
    end
    return fig, [ax_1, ax_2, ax_3]
end

function plot_comparison!(gax, surface1::SurfaceModule.Surface, surface2::SurfaceModule.Surface, phase::Float64)
    ax_1, ax_2, ax_3 = gax
    λ1_1, flux1_1 = get_spline(surface1, 1, phase)
    λ2_1, flux2_1 = get_spline(surface2, 1, phase)
    s1 = @. flux2_1 - flux1_1
    lines!(ax_1, λ1_1, s1)
    λ1_2, flux1_2 = get_spline(surface1, 2, phase)
    λ2_2, flux2_2 = get_spline(surface2, 2, phase)
    s2 = @. flux2_2 - flux1_2
    lines!(ax_2, λ1_2, s2)
    λ1_c, A_λ1, A_λ1_σ_plus, A_λ1_σ_minus = get_colour_law(surface1)
    λ2_c, A_λ2, A_λ2_σ_plus, A_λ2_σ_minus = get_colour_law(surface2)
    c2 = @. A_λ2 - A_λ1
    c1_plus = @. c2 + ((A_λ1_σ_plus - A_λ1) + (A_λ2_σ_plus - A_λ2))
    c1_minus = @. c2 + ((A_λ1 - A_λ1_σ_minus) + (A_λ2 - A_λ2_σ_minus))
    #band!(ax_3, λ1_c, c1_plus, c1_minus) 
    lines!(ax_3, λ1_c, c2)
end

function plot_comparison(surface1::SurfaceModule.Surface, surface2::SurfaceModule.Surface, strict_compare::Bool, phase::Float64)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M0 @ phase $phase")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M1 @ phase $phase")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law")
    if (!strict_compare) | (strict_compare & (surface1.name == surface2.name))
        plot_comparison!([ax_1, ax_2, ax_3], surface1, surface2, phase)
    end
end

function plot_comparison(surfaces1::Vector{SurfaceModule.Surface}, surfaces2::Vector{SurfaceModule.Surface}, strict_compare::Bool, phase::Float64)
    fig = Figure()
    ax_1 = Axis(fig[1, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M0 @ phase $phase")
    ax_2 = Axis(fig[2, 1], xlabel = "Wavelength", ylabel = "Flux", title = "M1 @ phase $phase")
    ax_3 = Axis(fig[3, 1], xlabel = "Wavelength", ylabel = "A(λ)", title = "Colour law resiudal")
    for surface1 in surfaces1
        for surface2 in surfaces2
            if (!strict_compare) | (strict_compare & (surface1.name == surface2.name))
                plot_comparison!([ax_1, ax_2, ax_3], surface1, surface2, phase)
            end
        end
    end
    return fig, [ax_1, ax_2, ax_3]
end

function save_plot(path::AbstractString, fig::Figure)
    save(path, fig)
end

end
