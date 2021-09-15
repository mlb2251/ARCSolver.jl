module Render
using Images
using ..Grids
using ImageView
using OffsetArrays

export to_img, pack_imgs, to_img_diff, to_img_diffgrid




ImageView.imshow(io::ARCIO) = imshow(to_img(io))
ImageView.imshow(io::ARCTask) = imshow(to_img(io))
ImageView.imshow(io::ARCGrid) = imshow(to_img(io))

@inline scale_grid(img::AbstractMatrix,scale::Int) = repeat(img; inner=(scale,scale))

# surprisingly verbose function to scale from a grid pixel location to a view of a range of pixels on a larger grid
@inline function view_px(img::AbstractArray, scale::Int, x::Int, y::Int)
    top_left_x = (x-1)*scale + 1
    top_left_y = (y-1)*scale + 1
    view(img,top_left_x:top_left_x+scale-1,top_left_y:top_left_y+scale-1)
end
@inline view_px(img::AbstractArray, scale::Int, I::CartesianIndex) = view_px(img,scale,I[1],I[2])

function gridlines!(img,cell_sz; color=colorant"gray")
    @assert mod.(size(img),cell_sz) == (0,0)
    img[1:cell_sz:end,:] .= color
    img[:,1:cell_sz:end] .= color
    img[end,:] .= color
    img[:,end] .= color
    img
end

function borders!(img, up=true, down=true, left=true, right=true; color=colorant"gray")
    up && (img[1,:] .= color)
    down && (img[end,:] .= color)
    left && (img[:,1] .= color)
    right && (img[:,end] .= color)
    img
end

function to_img(task::ARCTask; px_sz=20)
    pack_imgs(
    pack_imgs(dim=1,to_img.(task.ios,px_sz=px_sz)...),
    pack_imgs(dim=1,to_img.(task.test_ios,px_sz=px_sz)...)
    )
end

function to_img(io::ARCIO; px_sz=20)
    pack_imgs(to_img(io.i,px_sz=px_sz),to_img(io.o,px_sz=px_sz))
end

# function to_img(grid::ARCGrid; px_sz=20, scale=1)
#     # convert to colors
#     img = map(x -> colors[x+1], grid)

#     # scale a bit so each orig
#     img = scale_grid(img,px_sz)

#     # add 1 px border
#     if px_sz > 3
#         gridlines!(img,px_sz)
#     end

#     # scale some more!
#     scale_grid(img,scale)
# end

function to_img(grid::ARCGrid; px_sz=20)
    border_sz = px_sz > 3 ? 1 : 0
    to_img(RenderPixel.(grid,px_sz,border_sz) :: RenderGrid)
end

function to_img(grid::RenderGrid)
    @assert all(px->px.size==first(grid).size, grid) "not all RenderPixels are the same size in this RenderGrid"
    grid = to_img.(grid)
    # hvcat(size(grid),grid...) # doesnt work
    vcat([hcat(imgs...) for imgs in eachrow(grid)]...)
end

function to_img(px::RenderPixel)
    img = fill(px.color,px.size,px.size)
    if px.border_size > 0
        img[1:px.border_size,:] .= px.up_edge
        img[end:end-px.border_size,:] .= px.down_edge
        img[:,1:px.border_size] .= px.left_edge
        img[:,end:end-px.border_size] .= px.right_edge
    end
    img
end

# to_img(grid::OffsetArrays.OffsetMatrix{RenderPixel, RenderGrid}) = to_img(grid.)

function to_img(diff::ARCDiff; edges=true)

    function grayscale(img)
        img /= 9 # scale to 0.0-1.0
        img ./= 2 # scale to 0.0-0.5
        img[img.>0] .+= .3 # extra boost for nonzero (so black background stays dark)
        img .+ .2 # everyone gets a slight boost
    end

    # R G B are all indexed like A but B has some negative indices in it too
    R = grayscale(diff.A)
    G = grayscale(diff.B)
    B = Float64.(diff.match)

    # @show diff.B.offsets

    # img = colorview(RGB, paddedviews(0, R, G, B)...)
    R,G,B = 
    # @assert R.indices == G.indices == B.indices
    # x_offset, y_offset = R.indices   
    img = collect(colorview(RGB, paddedviews(0, R, G, B)...))
     # strip offsets to make colorview() and reinterpret() happy
    # img = OffsetArray(img, offsets...) # add offsets back in for edge-adding


    if edges
        img = scale_grid(img,5)
        for IA in CartesianIndices(diff.A)
            # IA = index in A
            # Ishared = index in the big shared image made by paddedviews (which indexes with 1 at the top right)
            # basically if an offset for B was <0 then we need to add that amount of offset to all our indices wrt A to get indices wrt the shared image
            # offset1 = min(diff.B.offsets[1],0)
            # offset2 = min(diff.B.offsets[2],0)
            # Ishared = IA + CartesianIndex(-offset1,-offset2) # we negate them because
            # @assert Ishared >= CartesianIndex(1,1)
            # IOffset = Tuple(IA) .+ min.(diff.A.offsets,(1,1))
            borders!(view_px(img,5,IA+diff.padded_offsets),diff.edges_match[IA,:]..., color=colorant"white")
        end
    end

    parent(img) # remove offsets for rendering
end

    # @show size(R) typeof(R) size(diff.edges_match) typeof(diff.edges_match)
    # @assert size(diff.match)[1:2] == size(R)
    # @assert size(diff.edges_match)[1:2] == size(R)
    # up_border = diff.edges_match[:,:,1] .== true
    # down_border = diff.edges_match[:,:,2] .== true
    # left_border = diff.edges_match[:,:,3] .== true
    # right_border = diff.edges_match[:,:,4] .== true

    # up_border = diff.edges_match[:,:,1]
    # down_border = diff.edges_match[:,:,2]
    # left_border = diff.edges_match[:,:,3]
    # right_border = diff.edges_match[:,:,4]

    # up_border, down_border, left_border, right_border, match


    # R,G,B = collect.(paddedviews(RenderPixel(colorant"black",px_sz,0), R, G, B))
    # R,G,B = collect.(paddedviews(0, R, G, B))

    # R = RenderPixel.(RGB.(R,0,0), px_sz, 0)
    # G = RenderPixel.(RGB.(0,G,0), px_sz, 0)
    # B = RenderPixel.(RGB.(0,0,B), px_sz, 0)



    # foreach(px -> px.up_edge =  , R[findall(up_border)])


    # @assert all(rgb->rgb.color.r < 1.,R)
    # @assert all(rgb->rgb.color.g < 1.,G)
    # @assert all(rgb->rgb.color.b < 1.,B)

    # @assert all(rgb->rgb.r == 0,G)
    # @assert all(rgb->rgb.g < 1.,g)
    # @assert all(rgb->rgb.b < 1.,b)


    # @show typeof(res)
    # @assert all(rgb->rgb.r < 1.,res)
    # @assert all(rgb->rgb.g < 1.,res)
    # @assert all(rgb->rgb.b < 1.,res)
    # res = to_img(R) .+ to_img(G) .+ to_img(B)
    # return res


    # R = to_img(RenderPixel.(RGB.(R,0,0), 1, 0))
    # G = to_img(RenderPixel.(RGB.(0,G,0), 1, 0))
    # B = to_img(RenderPixel.(RGB.(0,0,B), 1, 0))

    # return paddedviews(0, R, G, B)

    # return collect(colorview(RGB, paddedviews(zero(RGB), R, G, B)...))


    # return collect(colorview(RGB, paddedviews(0, R, G, B)...))
    
    # edges_match = diff.edges_match

    
# end

function to_img(diff_grid::ARCDiffGrid; edges=true)
    img_grid = to_img.(diff_grid.grid,edges=edges)
    img_grid = pack_imgs(
        [pack_imgs(imgs...,dim=2) for imgs in eachrow(img_grid)]...,
        dim=1
        )
    pack_imgs(to_img(diff_grid.A),to_img(diff_grid.B),img_grid,dim=2)
end


function pack_imgs(imgs::Matrix...; dim=2, pad=colorant"light gray", npad=5)
    @assert dim in [1,2]
    if dim == 2
        dim1 = maximum(size.(imgs,1))
        dim2 = sum(size.(imgs,2)) + (npad*(length(imgs)-1))
    else
        dim2 = maximum(size.(imgs,2))
        dim1 = sum(size.(imgs,1)) + (npad*(length(imgs)-1))
    end
    out = fill(pad, dim1, dim2)
    offset = 1
    if dim == 2
        for img in imgs
            d1,d2 = size(img)
            out[1:d1, offset:offset + d2 - 1] = img
            offset += d2 + npad
        end
    else
        for img in imgs
            d1,d2 = size(img)
            out[offset:offset + d1 - 1, 1:d2] = img
            offset += d1 + npad
        end
    end
    out
end


end