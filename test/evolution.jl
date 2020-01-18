using Test
using MTCGP
import Darwin
import Random

cfg = get_config("../cfg/test.yaml")

@testset "Mutation" begin

    parent = MTCGPInd(cfg)

    child = mutate(cfg, parent)

    @test any(parent.chromosome .!= child.chromosome)
    @test any(parent.genes .!= child.genes)

    child = goldman_mutate(cfg, parent)

    @test any(parent.chromosome .!= child.chromosome)
    @test any(parent.genes .!= child.genes)

    # this will sometime fail because of mathematically identical phenotypes,
    # which Goldman mutation does not account for
    # TODO: phenotypic goldman mutation

    # inputs = rand(4)
    # out_parent = process(parent, inputs)
    # out_child = process(child, inputs)
    # @test any(out_parent != out_child)
end

function rosenbrock(x::Array{Float64})
    sum([(1.0 - x[i])^2 + 100.0 * (x[i+1] - x[i]^2)^2
         for i in 1:(length(x)-1)])/200
end

function symbolic_evaluate(i::MTCGPInd; seed::Int64=0)
    Random.seed!(seed)
    inputs = rand(cfg["n_in"])
    output = process(i, inputs)
    target = rosenbrock(inputs)
    [-(output[1] - target)^2]
end

@testset "Symbolic Regression Evolution" begin
    e = MTCGP.evolution(cfg, symbolic_evaluate; id="test")

    Darwin.step!(e)
    @test length(e.population) == cfg["n_population"]
    best = sort(e.population)[end]
    @test best.fitness[1] <= 0.0
    @test e.gen == 1

    Darwin.run!(e)
    @test length(e.population) == cfg["n_population"]
    @test e.gen == cfg["n_gen"]
    println("Evolution step for symbolic regression")
    @timev Darwin.step!(e)
    new_best = sort(e.population)[end]
    println("Final fitness: ", new_best.fitness[1])
    @test new_best.fitness[1] <= 0.0
    @test !(new_best < best)
end
