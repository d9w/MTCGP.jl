
function f_add(x::MType, y::MType)
    (x .+ y) / 2.0
end

function f_mul(x::MType, y::MType)
    x .* y
end

function f_identity(x::MType, y::MType)
    x
end

cfg = Dict("rows"=>3, "columns"=>10, "nin"=>4, "nout"=>1, "nfitness"=>2,
           "functions"=>[f_add, f_mul, f_identity],
           "two_arity"=>BitArray([true, true, false]))

@testset "Individual construction" begin
    ind = Individual(cfg)

    @test length(ind.nodes) == 3 * 10 + 4
    for node in ind.nodes
        if node.active
            @test node.x >= 1
            @test node.x <= length(ind.nodes)
            @test node.y >= 1
            @test node.y <= length(ind.nodes)
        end
    end
end

@testset "Processing" begin
    ind = Individual(cfg)

    inputs = zeros(4)
    set_inputs(ind, inputs)
    for i in 1:4
        @test ind.buffer[i] == 0.0
    end
    output = process(ind)
    @test output[1] == 0.0
    for i in eachindex(ind.nodes)
        if ind.nodes[i].active
            @test ind.buffer[i] == 0.0
        end
    end

    output = process(ind, ones(4))
    @test output[1] == 1.0
    for i in eachindex(ind.nodes)
        if ind.nodes[i].active
            @test ind.buffer[i] == 1.0
        end
    end

    output = process(ind, Array{MType}([ones(3) for i in 1:4]))
    @test all(output[1] .== ones(3))
    for i in eachindex(ind.nodes)
        if ind.nodes[i].active
            @test all(ind.buffer[i] == ones(3))
        end
    end
end
