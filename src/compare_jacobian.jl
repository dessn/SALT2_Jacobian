using ArgParse
using Statistics
using ProgressBars
include("./jacobian.jl")
include("./surface.jl")

function parse_cli()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--strict_compare", "-c"
            help = "If includes, only compare surfaces with the same TRAINOPT id (I.e TRAINOPT000 to TRAINOPT000 and TRAINOPT001 to TRAINOPT001). Only works if both surface_1 and surface_2 point to multiple surfaces"
            action = :store_true
        "surface_1"
            help = "Should point to either the TRAINOPTxxx file which contans pca_1_opt1_final.list.gz and salt2_colour_correction.data.gz, or a directory which contains the TRAINOPTs"
            required = true
        "surface_2"
            help = "Should point to either the TRAINOPTxxx file which contans pca_1_opt1_final.list.gz and salt2_colour_correction.data.gz, or a directory which contains the TRAINOPTs"
            required = true
    end

    return parse_args(s)
end

function percent_diff(a, b)
    return @. abs(100 * (a - b) / abs(a))
end

function compare_surfaces(surface_1::surface, surface_2::surface, strict_compare)
    spline_1_diff = percent_diff(surface_1.spline.components[1].values, surface_2.spline.components[1].values)
    spline_2_diff = percent_diff(surface_1.spline.components[2].values, surface_2.spline.components[2].values)
    colour_law_diff = percent_diff(surface_1.colour_law.a, surface_2.colour_law.a)
    return ((surface_1.name, surface_2.name), median(spline_1_diff)), ((surface_1.name, surface_2.name), median(spline_2_diff)), ((surface_1.name, surface_2.name), median(colour_law_diff))
end

function compare_surfaces(surface_1::surface, surface_2, strict_compare)
    spline_1_diff = []
    spline_2_diff = []
    colour_law_diff = []
    for surf in tqdm(surface_2)
        s1, s2, cl = compare_surfaces(surface_1, surf)
        push!(spline_1_diff, s1)
        push!(spline_2_diff, s2)
        push!(colour_law_diff, cl)
    end
    return spline_1_diff, spline_2_diff, colour_law_diff
end

function compare_surfaces(surface_1, surface_2::surface, strict_compare)
    return compare_surfaces(surface_2, surface_1, strict_compare)
end

function compare_surfaces(surface_1, surface_2, strict_compare)
    spline_1_diff = []
    spline_2_diff = []
    colour_law_diff = []
    for surf1 in tqdm(surface_1)
        for surf2 in surface_2
            if strict_compare && surf1.name != surf2.name
                continue
            end
            s1, s2, cl = compare_surfaces(surf1, surf2, strict_compare)
            push!(spline_1_diff, s1)
            push!(spline_2_diff, s2)
            push!(colour_law_diff, cl)
        end
    end
    return spline_1_diff, spline_2_diff, colour_law_diff
end

function main(parsed_args)
    strict_compare = parsed_args["strict_compare"]
    surface_1_path = parsed_args["surface_1"]
    surface_2_path = parsed_args["surface_2"]
    if occursin("TRAINOPT", uppercase(surface_1_path))
        surface_1 = surface(surface_1_path, "_", surface_1_path)
    else
        surface_1 = [surface(split(path, "/")[end], "_", joinpath(surface_1_path, path)) for path in readdir(surface_1_path) if occursin("TRAINOPT", uppercase(path))]
    end
    if occursin("TRAINOPT", uppercase(surface_2_path))
        surface_2 = surface(surface_2_path, "_", surface_2_path)
    else
        surface_2 = [surface(split(path, "/")[end], "_", joinpath(surface_2_path, path)) for path in readdir(surface_2_path) if occursin("TRAINOPT", uppercase(path))]
    end
    println("Comparing $surface_1_path with $surface_2_path")
    s1, s2, cl = compare_surfaces(surface_1, surface_2, strict_compare)
    s1n = [i[1] for i in s1]
    s1v = [i[2] for i in s1]
    s2n = [i[1] for i in s2]
    s2v = [i[2] for i in s2]
    cln = [i[1] for i in cl]
    clv = [i[2] for i in cl]
    println("Median difference in spline 1 components: $(median(s1v))%")
    println("Median difference in spline 2 components: $(median(s2v))%")
    println("Median difference in colour law components: $(median(clv))%")
    s1i = argmax(s1v)
    s2i = argmax(s2v)
    cli = argmax(clv)
    println("Max difference in spline 1 components: $(s1v[s1i])% for $(s1n[s1i])")
    println("Max difference in spline 2 components: $(s2v[s2i])% for $(s2n[s2i])")
    println("Max difference in colour law components: $(clv[cli])% for $(cln[cli])")

end

if !isinteractive()
    parsed_args = parse_cli()
    main(parsed_args)
end

