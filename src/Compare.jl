module Compare

# External Packages
using Statistics

# Internal Packages
using ..Tools
using ..SurfaceModule
using ..JacobianModule

# Exports
export compare_surfaces

function percent_diff(a, b)
    return 100 * abs((a - b) / (0.5 * (a + b)))
end

# Returns the percentage different in the splines and colour law of the two surfaces 
function compare_surface(surface_1::Surface, surface_2::Surface)
    spline_1_diff = percent_diff.(surface_1.spline.components[1].values, surface_2.spline.components[1].values)
    spline_2_diff = percent_diff.(surface_1.spline.components[2].values, surface_2.spline.components[2].values)
    colour_law_diff = percent_diff.(surface_1.colour_law.a, surface_2.colour_law.a)
    return spline_1_diff, spline_2_diff, colour_law_diff
end

function compare_surfaces(surfaces_1, surfaces_2, strict_compare::Bool)
    comparison = Dict()
    for s1 in surfaces_1
        for s2 in surfaces_2
            s1_name = split(splitpath(s1)[end], ".")[1]
            s2_name = split(splitpath(s2)[end], ".")[1]
            if strict_compare & (s1_name != s2_name)
                continue
            end
            surface_1 = Surface(s1_name, "", s1)
            surface_2 = Surface(s2_name, "", s2)
            comparison[(s1_name, s2_name)] = compare_surface(surface_1, surface_2) 
            
        end
    end
    return comparison 
end

end
