module Render
using Images
using ..Grids
using ImageView
using OffsetArrays

export to_img, pack_imgs, to_img_diff, to_img_diffgrid

ImageView.imshow(io::Union{ARCIO,ARCTask,ARCDiff,ARCDiffGrid,ARCGrid}) = imshow(to_img(io))

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

# TODO convert away from Renderpixel some time
function to_img(grid::ARCGrid; px_sz=20)
    img = map(color->colors[color+1], grid)
    img = scale_grid(img,px_sz)
    if px_sz > 3
        for I in CartesianIndices(grid)
            borders!(view_px(img,px_sz,I))
        end
    end
    img
end

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

    img = collect(colorview(RGB, paddedviews(0, R, G, B)...))

    if edges
        img = scale_grid(img,5)
        for IA in CartesianIndices(diff.A)
            borders!(view_px(img,5,IA+diff.padded_offsets),diff.edges_match[IA,:]..., color=colorant"white")
        end
    end

    parent(img) # remove offsets for rendering
end

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