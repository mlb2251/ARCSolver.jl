module Grids

export ARCGrid,ARCIO,ARCTask, ARCDiff, ARCDiffGrid, edges_of_grid, RenderGrid, RenderPixel, colors
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


mutable struct RenderPixel
    color:: RGB
    size:: Int
    border_size:: Int
    up_edge :: RGB
    down_edge :: RGB
    left_edge :: RGB
    right_edge :: RGB
end
# convert Int8 to RGB
RenderPixel(color::Int8,args...) = RenderPixel(colors[color+1],args...)
# if only color+size are provided, add borders of the same color (ie invisible borders)
RenderPixel(color,size) = RenderPixel(color, size, 0, colorant"gray", colorant"gray", colorant"gray", colorant"gray")
# if only color+size are provided, add borders of the same color (ie invisible borders)
RenderPixel(color,size,border_size) = RenderPixel(color, size, border_size, colorant"gray", colorant"gray", colorant"gray", colorant"gray")

# function RenderGrid(grid::ARCGrid; args...)
#     border_sz = px_sz > 3 ? 1 : 0
#     RenderPixel.(grid,border_sz) :: RenderGrid
# end

const RenderGrid = Matrix{RenderPixel}


struct ARCTask
    ios::Vector{ARCIO}
    test_ios::Vector{ARCIO}
    path::String
end


struct ARCDiff
    A :: ARCGrid
    B :: OffsetArrays.OffsetMatrix
    # match :: OffsetArrays.OffsetMatrix{Bool,BitMatrix}
    match :: BitMatrix
    # edges_match :: OffsetArrays.OffsetArray{Bool,3, BitArray{3}}
    edges_match :: BitArray{3}

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