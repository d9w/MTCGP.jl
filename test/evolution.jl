using Test
using MTCGP

cfg = get_config("../cfg/test.yaml")

@testset "Mutation" begin

    parent = Individual(cfg)

    child = mutate(cfg, parent)

    @test any(parent.chromosome .!= child.chromosome)
    @test any(parent.genes .!= child.genes)

    child = goldman_mutate(cfg, parent)

    @test any(parent.chromosome .!= child.chromosome)
    @test any(parent.genes .!= child.genes)

    inputs = rand(4)
    out_parent = process(parent, inputs)
    out_child = process(child, inputs)

    # this will sometime fail because of mathematically identical phenotypes,
    # which Goldman mutation does not account for
    @test any(out_parent != out_child)
end
