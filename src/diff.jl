module Diff
using LinearAlgebra
using OffsetArrays
using PaddedViews
export diff_grids
using ..Render, ..Grids


index_overlap(A,B) = length(intersect(CartesianIndices(A),CartesianIndices(B)))

function diff_grids(A::ARCGrid, B::ARCGrid)
    Asz1,Asz2 = size(A)
    Bsz1,Bsz2 = size(B)
    """
    Slide B over A
    Initially B sits entirely inside of A (or vis versa if sizes are swapped, but that doesn't affect anything)
    with [1,1] as their shared top left corner.
    We will be using OffsetArrays here, and specifically B will be the offset array
    and A will always keep its indices (1:Asz1, 1:Asz2).
    We want to start B such that the bottom right pixel of B lines up with the top left pixel of A.
    Since we use the indices of A this is [1,1] wrt A, and so to make the bottom right [Bsz1,Bsz2] pixel
    of B point to [1,1] we basically want all of Bs indices to be <=0 until that one pixel. This ends up
    being `OffsetArray(B, -Bsz1+1, -Bsz1+1)`.
    """
    # todo: precompute these instead of computing them every time
    edges_A = edges_of_grid(A)
    edges_B = edges_of_grid(B)

    oBinit = OffsetArray(B, -Bsz1+1, -Bsz2+1)
    edges_oBinit = OffsetArray(edges_B, -Bsz1+1, -Bsz2+1, 0)

    # highest offests to go to
    d1_end = Asz1+Bsz1-2
    d2_end = Asz2+Bsz2-2

    # sanity checks
    @assert index_overlap(A,oBinit) == 1
    @assert index_overlap(A,OffsetArray(oBinit, d1_end, d2_end)) == 1


    diff_grid = ARCDiffGrid(
        Matrix{ARCDiff}(undef, d1_end+1, d2_end+1),
        A::ARCGrid,
        B::ARCGrid,
    )

    for d1 in 0:d1_end, d2 in 0:d2_end
        # slide B using offset
        oB = OffsetArray(oBinit, d1, d2)
        edges_oB = OffsetArray(edges_oBinit, d1, d2, 0)

        # restrict to the overlapping region
        # shared_indices = intersect(CartesianIndices(A),CartesianIndices(oB))
        # oBint = oB[shared_indices]
        # Aint = A[shared_indices]
        # edges_Aint = edges_A[shared_indices,:]
        # edges_oBint = edges_oB[shared_indices,:]
        Aint, oBint = paddedviews(-1, A, oB)
        edges_Aint, edges_oBint = paddedviews(false,edges_A, edges_oB)

        # nonzero pixels that match
        match = falses(size(A))
        match[findall(Aint .== oBint .> 0)] .= true
        # @show typeof(match)

        # edges that match
        edges_match = falses(size(edges_A))
        edges_match[findall(edges_Aint .== edges_oBint .== true)] .= true
        # edges_match,_ = paddedview(0, edges_match,A) # pad edges_match to match A
        
        diff_grid.grid[d1+1,d2+1] = ARCDiff(A,oB,match,edges_match)

        # helpful debug comment:
        # println("$d1 $d2 -> $(sum(match))/$(index_overlap(A,oB))")
    end
    diff_grid
end



end