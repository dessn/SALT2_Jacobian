using CodecZlib
using Tar

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

function compress(source, dest)
    open(dest, write=true) do tar_gz
        tar = GzipCompressorStream(tar_gz)
        Tar.create(source, tar)
        close(tar)
    end
end
