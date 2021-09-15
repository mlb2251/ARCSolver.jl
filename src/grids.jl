module Grids

export ARCGrid,ARCIO,ARCTask, ARCDiff, ARCDiffGrid, edges_of_grid, colors
import OffsetArrays
using Images

const colors = [
    colorant"#000000",
    colorant"#0074D9",
    colorant"#FF4136",
    colorant"#2ECC40",
    colorant"#FFDC00",
    colorant"#AAAAAA",
    colorant"#F012BE",
    colorant"#FF851B",
    colorant"#7FDBFF",
    colorant"#870C25",
]

const ARCGrid = Matrix{Int8}
const ARCIO = NamedTuple{(:i,:o),Tuple{ARCGrid,ARCGrid}}



struct ARCTask
    ios::Vector{ARCIO}
    test_ios::Vector{ARCIO}
    path::String
end


struct ARCDiff
    A :: ARCGrid # normal indices
    B :: OffsetArrays.OffsetMatrix # index like A! has whatever size B has
    # match :: OffsetArrays.OffsetMatrix{Bool,BitMatrix}
    match :: BitMatrix # index like A (same size as A)
    # edges_match :: OffsetArrays.OffsetArray{Bool,3, BitArray{3}}
    edges_match :: BitArray{3} # index like A (same size as A)
    offsets :: Tuple{Int,Int} # offset of B relative to A (literally ArcDiff.B.offsets)
    padded_offsets :: CartesianIndex{2} # if you collect(paddedviews(fill,A,B)) and need to erase the, adding these offsets to A indices will give you indices in the larger image (basically, if B has negative offsets (up and to the left of A) then we need to shift A indices by the magnitude of that offset in the positive direction)
end
function ARCDiff(A,B,match,edges_match)
    ARCDiff(
        A,
        B,
        match,
        edges_match,
        B.offsets,
        CartesianIndex(.-min.(B.offsets,0))
    )
end

struct ARCDiffGrid
    grid :: Matrix{ARCDiff}
    A :: ARCGrid
    B :: ARCGrid
end



function edges_of_grid(grid::ARCGrid)
    edges = falses(size(grid)...,4) :: BitArray
    # Is = CartesianIndices(grid)
    # Ifirst, Ilast = first(Is), last(Is)
    # for I in Is:
    #     edges[I,0] = 

    # up and down calculated both at once, since "down" for each cell is same as "up" for the one below it
    edges[2:end,:,1] .= edges[1:end-1,:,2] .= grid[2:end,:] .!= grid[1:end-1,:]
    # left and right - all the same stuff but with d1 and d2 swapped by symmetry
    edges[:,2:end,3] .= edges[:,1:end-1,4] .= grid[:,2:end] .!= grid[:,1:end-1]

    return edges


#     edges[:,:,1] .= grid != OffsetArray(grid,-1,0) # up
#     edges[:,:,2] .= grid != OffsetArray(grid,1,0) # down
#     edges[:,:,3] .= grid != OffsetArray(grid,0,-1) # left
#     edges[:,:,4] .= grid != OffsetArray(grid,0,1) # right
end

# struct ARCCell
#     color :: Int8
#     up :: Bool
#     down :: Bool
#     left :: Bool
#     right :: Bool
# end
end