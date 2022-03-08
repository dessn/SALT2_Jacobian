module Train

# External Packages
using CodecZlib 
using ProgressBars

# Internal Packages
using ..Tools
using ..SurfaceModule
using ..JacobianModule

# Exports
export train_surfaces

# Main function for training a surface
function train_surfaces(input_file, base_surface_path, jacobian, outdir)
    input_trainopts = parse_input_file(input_file)
    base_surface = Surface("TRAINOPT000", "", base_surface_path)
    cp(base_surface_path, joinpath(outdir, "TRAINOPT000.tar.gz"), force=true)

    base_spline_1 = base_surface.spline.components[1].values
    base_spline_2 = base_surface.spline.components[2].values
    base_colour_law = base_surface.colour_law.a
    
    # For each trainopt, train a surface
    Threads.@threads for (i, trainopt) in ProgressBar(collect(enumerate(input_trainopts)))
        spline_1_offset = zeros(length(base_spline_1))
        spline_2_offset = zeros(length(base_spline_2))
        colour_law_offset = zeros(length(base_colour_law))
        kv = Dict(v => k for (k, v) in jacobian.trainopts)
        # Calculate offsets from trainopt
        for (opt, offset) in trainopt
            n = kv[opt]
            offset = parse(Float64, offset)
            j_offset = jacobian.offsets[n]
            j_offset = parse(Float64, j_offset)
            j_spline_1 = jacobian.spline_1[n]
            j_spline_2 = jacobian.spline_2[n]
            j_colour_law = jacobian.colour_law[n]
            spline_1_offset += j_spline_1 .* (offset / j_offset)
            spline_2_offset += j_spline_2 .* (offset / j_offset)
            colour_law_offset += j_colour_law .* (offset / j_offset)
        end
        new_spline_1 = base_spline_1 + spline_1_offset
        new_spline_2 = base_spline_2 + spline_2_offset
        new_colour_law = base_colour_law + colour_law_offset
        

        # Copy TRAINOPT000 files over
        destination_dir = joinpath(outdir, "TRAINOPT$(lpad(i,3,"0")).tar.gz")
        trainopt_dir_orig = uncompress(joinpath(outdir, "TRAINOPT000.tar.gz"))
        trainopt_dir = trainopt_dir_orig
        trainopt_dir = trainopt_dir[1: end-3] * lpad(i, 3, "0")
        mv(trainopt_dir_orig, trainopt_dir)

        # Overwrite spline file
        spline_file = joinpath(trainopt_dir, "pca_1_opt1_final.list.gz")
        new_spline_file = open(GzipDecompressorStream, spline_file) do io
            return readlines(io)
        end

        new_spline_file[2] = join(vcat(split(new_spline_file[2])[1:7], new_spline_1), " ")
        new_spline_file[3] = join(vcat(split(new_spline_file[3])[1:7], new_spline_2), " ")
        new_spline_file[end-8:end-5] = [string(a) for a in new_colour_law]
        new_spline_file = join(new_spline_file, "\n")

        open(GzipCompressorStream, spline_file, "w") do io
            write(io, new_spline_file)
        end

        # Overwrite color correction file
        colour_law_file = joinpath(trainopt_dir, "salt2_color_correction.dat.gz")
        new_colour_law_file = open(GzipDecompressorStream, colour_law_file) do io
            return readlines(io)
        end
        
        new_colour_law_file[2:5] = [string(a) for a in new_colour_law]
        new_colour_law_file = join(new_colour_law_file, "\n")

        open(GzipCompressorStream, colour_law_file, "w") do io
            write(io, new_colour_law_file)
        end

        # Save and compress final surface
        trainopt_dir = join(split(trainopt_dir, "/")[1:end-1], "/")
        compress(trainopt_dir, destination_dir) 
    end
end
        
# Parse the input file used by submit_batch
function parse_input_file(input_file)
    raw = open(input_file, "r") do io
        return readlines(io)
    end
    trainopts = [line for line in raw if occursin("SHIFT", line)]
    trainopts = [split(line, "#")[1] for line in trainopts]
    trainopts = [split(line)[2:end] for line in trainopts]
    trainopts = [process_trainopts(line) for line in trainopts]
    return trainopts
end

# Get trainopts into a consistent form
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

end
