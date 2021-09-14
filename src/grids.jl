

module Grids

export ARCGrid,ARCIO,ARCTask, DiffGrid

const ARCGrid = Matrix{Int8}
const ARCIO = NamedTuple{(:i,:o),Tuple{ARCGrid,ARCGrid}}

struct ARCTask
    ios::Vector{ARCIO}
    test_ios::Vector{ARCIO}
    path::String
end

struct DiffGrid
    grid :: Matrix{Any}
    A :: Matrix
    B :: Matrix
end


struct ARCCell
    color :: Int8
    up :: Bool
    down :: Bool
    left :: Bool
    right :: Bool
end