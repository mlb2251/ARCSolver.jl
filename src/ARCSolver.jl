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

import Images

function main()
    tasks = load_tasks()
    diffgrids = Vector{DiffGrid}(undef, length(tasks))
    for i in 1:length(tasks)
        println(i)
        diffgrids[i] = diff_grids(tasks[i].ios[1]...)
    end

    for (grid,task) in zip(diffgrids,tasks)
        Images.save("out/diffs/$(splitpath(task.path)[end]).png",to_img(grid))
    end
    println(sizeof(diffgrids))
    println(sizeof(tasks))
end

end
