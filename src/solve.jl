module Solve

export solve, load_tasks
using Crayons
using LinearAlgebra
import JSON
using ..Render
using ..Grids

println("imports done")

function task_of_json(json, path)
    ARCTask(
        ios_of_json(json["train"]),
        ios_of_json(json["test"]),
        path
    )
end

function ios_of_json(json::Array)
    io_of_json.(json)
end

function io_of_json(json)
    (i=grid_of_json(json["input"]), o=grid_of_json(json["output"]))
end

function grid_of_json(json)
    # transpose to match how the official challenge displays images
    transpose(convert(Matrix{Int8}, hcat(json...)))
end


function load_tasks(mode=:train)
    @assert mode in [:train, :test]
    path = Dict(:train => "data/training", :test => "data/evaluation")[mode]
    train_files = readdir(path, join=true)
    print(crayon"yellow", "loading $mode tasks...", crayon"reset")
    tasks = task_of_json.(JSON.parsefile.(train_files), train_files)
    println(crayon"yellow", "loaded $(length(tasks)) tasks", crayon"reset")
    tasks
end



function solve()

end


end