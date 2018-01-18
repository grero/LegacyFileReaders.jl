module LegacyFileReaders
using FileIO
import FileIO.load
using Base.Mmap

struct DataHeader
    headersize::UInt32
    samplingrate::UInt32
    nchannels::UInt16
    npoints::UInt64
    transpose::Bool
end

struct DataPacket{T<:Real}
    header::DataHeader
    data::AbstractArray{T,2}
end

datatypes = Dict(1 => UInt8,
                 2 => UInt8,
                 3 => Int8,
                 4 => Int16,
                 5 => Int32,
                 6 => Int64,
                 7 => UInt8,
                 8 => UInt16,
                 9 => UInt32,
                 10 => UInt64,
                 11 => Float16,
                 12 => Float32,
                 13 => Float64,
                 14 => Float64)

function FileIO.load(ff::File{format"NPTD"})
    datatype = Int16
    header = open(ff.filename) do fid 
        header_size = read(fid, UInt32)
        num_channels = read(fid, UInt16)
        transpose = read(fid, UInt8)
        sampling_rate = read(fid, UInt32)
        seekend(fid)
        fsize = position(fid)
        npoints = div(fsize - header_size,sizeof(datatype))
        npoints = div(npoints, num_channels)
        DataHeader(header_size, sampling_rate, num_channels, npoints,transpose == one(UInt8)) 
    end
    DataPacket(header, Mmap.mmap(ff.filename, Array{datatype, 2}, (Int(header.nchannels), Int(header.npoints)), Int(header.headersize)))
end
end#module
