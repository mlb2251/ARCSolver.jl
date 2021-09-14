module ARCSolver

export main

using Reexport
include("grids.jl")
@reexport using .Grids

include("render.jl")
@reexport using .Render

include("solve.jl")
@reexport using .Solve

include("diff.jl")
@reexport using .Diff

function main()
    tasks = load_tasks()
    images = Vector{Any}(undef, length(tasks))
    for i in 1:length(tasks)
        println(i)
        images[i] = diff_grids(tasks[i].ios[1]...)
    end
end

end
