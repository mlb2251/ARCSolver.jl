module ARCSolver

export main, simple

using Reexport
include("grids.jl")
@reexport using .Grids

include("render.jl")
@reexport using .Render

include("solve.jl")
@reexport using .Solve

include("diff.jl")
@reexport using .Diff

using Images, ImageView

function main()
    tasks = load_tasks()
    diffgrids = Vector{ARCDiffGrid}(undef, length(tasks))
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

function simple()
    task = load_tasks(n=20)[14]
    dg = diff_grids(task.ios[1]...)
    to_img(dg)
end

end
