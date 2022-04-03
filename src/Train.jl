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
function train_surfaces(input_trainopts, base_surface_path, jacobian, outdir, batch_mode)
    base_surface = Surface("TRAINOPT000", "", base_surface_path)
    if !batch_mode
        new_base_surface_path = joinpath(outdir, "TRAINOPT000.tar.gz")
        cp(base_surface_path, new_base_surface_path, force=true)
    end

    base_spline_1 = base_surface.spline.components[1].values
    base_spline_2 = base_surface.spline.components[2].values
    base_colour_law = base_surface.colour_law.a
    
    # For each trainopt, train a surface
    #for (i, trainopt) in ProgressBar(collect(enumerate(input_trainopts)))
    for (i, trainopt) in collect(enumerate(input_trainopts))
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
        trainopt_dir_orig = uncompress(base_surface_path)
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
        if !batch_mode
            trainopt_dir = join(split(trainopt_dir, "/")[1:end-1], "/")
            destination_dir = joinpath(outdir, "TRAINOPT$(lpad(i,3,"0")).tar.gz")
            compress(trainopt_dir, destination_dir) 
        else
            destination_dir = outdir 
            allowed_files = ["salt2_color_correction.dat.gz", "salt2_lc_dispersion_scaling.dat.gz", "salt2_lc_relative_variance_1.dat.gz", "salt2_spec_variance_1.dat.gz", "salt2_color_dispersion.dat.gz", "salt2_lc_relative_covariance_01.dat.gz", "salt2_spec_covariance_01.dat.gz", "salt2_template_0.dat.gz", "SALT2.INFO", "salt2_lc_relative_variance_0.dat.gz", "salt2_spec_variance_0.dat.gz", "salt2_template_1.dat.gz"]
            for file in readdir(trainopt_dir)
                if file in allowed_files
                    cp(joinpath(trainopt_dir, file), joinpath(destination_dir, file), force=true)
                end
            end
        end
    end
    return length(input_trainopts)
end

function train_surfaces(input_trainopts::Vector{String}, base_surface_path, jacobian, outdir, batch_mode)
    input_trainopts = process_trainopts(input_trainopts)
    return train_surfaces(input_trainopts, base_surface_path, jacobian, outdir, batch_mode)
end
        
# Get trainopts into a consistent form
function process_trainopts(opts)
    mag_eq = ["CfA3_STANDARD", "Calan/Tololo", "Other"]
    wave_eq = ["CfA3_STANDARD", "Calan/Tololo", "Other", "CfA2", "CfA1"]
    rtn = [] 
    for trainopt in opts
        elem = Dict()
        trainopt = split(trainopt)
        opt_list = []
        for opt in trainopt
            if occursin("SHIFT", opt)
                push!(opt_list, [opt])
            else
                if opt_list[end][end] == "SHIFTLIST_FILE"
                    opt_list = opt_list[1:end-1] # Remove previous element
                    open(opt, "r") do io
                        lines = readlines(io)
                        for line in lines
                            push!(opt_list, split(line))
                        end
                    end
                else
                    push!(opt_list[end], opt)
                end
            end
        end
        for opt in opt_list
            is_mag = opt[1] == "MAGSHIFT"
            if is_mag
                @debug "Found MAGSHIFT"
                eq = mag_eq
            else
                @debug "Found WAVESHIFT"
                eq = wave_eq
            end
            if opt[1] == "LAMSHIFT"
                @debug "Updated LAMSHIFT to WAVESHIFT"
                opt[1] = "WAVESHIFT"
            end
            if opt[2] in eq
                @debug "Updating $(opt[2]) to $(eq[1])"
                opt[2] = eq[1]
                opt[3] = uppercase(opt[3])
            end
            opt3 = split(opt[3], ',')
            opt4 = split(opt[4], ',')
            for i in 1:length(opt3)
                k = "$(opt[1]) $(opt[2]) $(opt3[i])"
                v = opt4[i]
                elem[k] = opt4[i]
                @debug "$k = $v"
            end
        end
        push!(rtn, elem)
    end
    return rtn
end

end
