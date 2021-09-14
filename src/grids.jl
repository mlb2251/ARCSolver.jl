

module Grids

export ARCGrid,ARCIO,ARCTask

const ARCGrid = Matrix{Int8}
const ARCIO = NamedTuple{(:i,:o),Tuple{ARCGrid,ARCGrid}}

struct ARCTask
    ios::Vector{ARCIO}
    test_ios::Vector{ARCIO}
    path::String
end

end