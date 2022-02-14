module Tools
# Generic functions to be used throughout

# External Packages
using CodecZlib
using Tar

# Exports
export uncompress
export compress
export ensure_list

# Uncompress if source is compressed, otherwise just return source
function uncompress(source)
    if occursin(".tar.gz", source)
        source = open(source) do tar_gz
            tar = GzipDecompressorStream(tar_gz)
            s = readdir(Tar.extract(tar), join=true)[1]
            close(tar)
            return s
        end
    end
    return source
end

# Compress source into .tar.gz
function compress(source, dest)
    open(dest, write=true) do tar_gz
        tar = GzipCompressorStream(tar_gz)
        Tar.create(source, tar)
        close(tar)
    end
end

# Ensure input is a list
function ensure_list(list)
    if typeof(list) <: Vector
        return list
    end
    return [list]
end

end
