module Diff
using LinearAlgebra
using OffsetArrays
using PaddedViews
export diff_grids
using ..Render



 
index_overlap(A,B) = length(intersect(CartesianIndices(A),CartesianIndices(B)))

function diff_grids(A::Matrix, B::Matrix)
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
    oBinit = OffsetArray(B, -Bsz1+1, -Bsz2+1)
    # highest offests to go to
    d1_end = Asz1+Bsz1-2
    d2_end = Asz2+Bsz2-2
    # sanity checks
    @assert index_overlap(A,oBinit) == 1
    @assert index_overlap(A,OffsetArray(oBinit, d1_end, d2_end)) == 1
    imgs = Any[]
    col_imgs = Any[]
    for d1 in 0:d1_end, d2 in 0:d2_end
        # slide B using offset
        oB = OffsetArray(oBinit, d1, d2)
        # pad with -1s to allow for .== elemwise comparison (we'll ignore the -1s during comparison)
        aa, bb = paddedviews(-1, A, oB)
        match = (aa .> 0) .& (bb .== aa) # bitmatrix relative to A indicating where theyre identical and nonzero
        println("$d1 $d2 -> $(sum(match))/$(index_overlap(A,oB))")
        push!(col_imgs, to_img_diff(A, oB, Float64.(match)))
        if d2 == d2_end
            push!(imgs, pack_imgs(col_imgs...,dim=2))
            col_imgs = Any[]
        end
    end
    pack_imgs(imgs...,dim=1)
end

end