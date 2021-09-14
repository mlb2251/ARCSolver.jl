module Transform
using LinearAlgebra

scale2(x::Matrix) = repeat(x,inner=(2,2))
scale3(x::Matrix) = repeat(x,inner=(3,3))
scale4(x::Matrix) = repeat(x,inner=(4,4))
rot90(x::Matrix) = rotr90(x)
rot180(x::Matrix) = rotr90(x,2)
rot270(x::Matrix) = rotr90(x,3)
vflip(x::Matrix) = reverse(x,dims=1)
hflip(x::Matrix) = reverse(x,dims=2)
diagflip1(x::Matrix) = transpose(x)
diagflip1(x::Matrix) = reverse(transpose(x))

end