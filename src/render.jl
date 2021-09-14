module Render
using Images
using ..Grids
using ImageView

export colors, to_img, pack_imgs, to_img_diff

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


ImageView.imshow(io::ARCIO) = imshow(to_img(io))
ImageView.imshow(io::ARCTask) = imshow(to_img(io))
ImageView.imshow(io::ARCGrid) = imshow(to_img(io))


function to_img(task::ARCTask; px_sz=20, scale=1)
    pack_imgs(
    pack_imgs(dim=1,to_img.(task.ios,px_sz=px_sz,scale=scale)...),
    pack_imgs(dim=1,to_img.(task.test_ios,px_sz=px_sz,scale=scale)...)
    )
end

function to_img(io::ARCIO; px_sz=20, scale=1)
    pack_imgs(to_img(io.i,px_sz=px_sz,scale=scale),to_img(io.o,px_sz=px_sz,scale=scale))
end

# function to_img(grid::ARCGrid; px_sz=20, img_sz=400)
#     # convert to colors
#     img = map(x -> colors[x+1], grid)
#     # scale a bit
#     img = repeat(img; inner=(px_sz,px_sz))
#     # add 1 pixel grid (prior to more scaling)
#     img[1:px_sz:end,:] .= colorant"gray"
#     img[:,1:px_sz:end] .= colorant"gray"
#     img[end,:] .= colorant"gray"
#     img[:,end] .= colorant"gray"

#     # scale to output image size
#     imresize(img, img_sz, img_sz)
# end

function to_img(grid::ARCGrid; px_sz=20, scale=1)
    # convert to colors
    img = map(x -> colors[x+1], grid)

    # scale a bit so each orig
    img = repeat(img; inner=(px_sz,px_sz))

    # add 1 px border
    if px_sz > 1
        img[1:px_sz:end,:] .= colorant"gray"
        img[:,1:px_sz:end] .= colorant"gray"
        img[end,:] .= colorant"gray"
        img[:,end] .= colorant"gray"
    end

    # scale some more!
    repeat(img; inner=(scale,scale))
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


function to_img_diff(A,B,match)
    
    
    function torgb(x)
        z = x/20 # scale to be <.5 so we dont exceed 1.0

        z[z.>0] .+= .3 # extra boost for nonzero

        z .+= .15 # everyone gets a slight boost
        z
    end

    a = torgb(A) # 12336
    b = torgb(B) # 2960
    m = Float64.(match) # 7360

    # 26224 bytes
    res = collect(colorview(RGB, paddedviews(0, a, b, m)...))
    return res
end

end
