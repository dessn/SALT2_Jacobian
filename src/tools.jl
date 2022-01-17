using CodecZlib
using Tar

# Generic functions to be used throughout

# Uncompress if source is compressed, otherwise just return source
function uncompress(source)
    if occursin(".tar.gz", source)
        open(source) do tar_gz
            tar = GzipDecompressorStream(tar_gz)
            source = readdir(Tar.extract(tar), join=true)[1]
            close(tar)
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
function ensure_list(in)
    if typeof(in) <: Vector
        return in
    end
    return [in]
end
