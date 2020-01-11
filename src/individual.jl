export Node, Individual

function null(args...)::Nothing
    nothing
end

struct Node
    x::Int8
    y::Int8
    f::Function
    active::Bool
end

struct Individual
    chromosome::Array{Float64}
    genes::Array{Int8}
    outputs::Array{Int8}
    nodes::Array{Node}
    buffer::Array{MType}
    fitness::Array{Float64}
end

function Individual(cfg::Dict, chromosome::Array{Float64}, genes::Array{Int8},
                    outputs::Array{Int8})::Individual
    R = cfg["rows"]
    C = cfg["columns"]
    nodes = Array{Node}(undef, R * C + cfg["nin"])
    for i in 1:cfg["nin"]
        nodes[i] = Node(0, 0, null, false)
    end
    i = cfg["nin"]
    active = find_active(cfg, genes, outputs)
    for y in 1:C
        for x in 1:R
            i += 1
            nodes[i] = Node(genes[x, y, 1], genes[x, y, 2],
                            cfg["functions"][genes[x, y, 3]],
                            active[x, y])
        end
    end
    buffer = Array{MType}(nothing, R * C + cfg["nin"])
    fitness = -Inf .* ones(cfg["nfitness"])
    Individual(chromosome, genes, outputs, nodes, buffer, fitness)
end

function Individual(cfg::Dict, chromosome::Array{Float64})::Individual
    R = cfg["rows"]
    C = cfg["columns"]
    genes = reshape(chromosome[1:(R*C*3)], R, C, 3)
    maxs = repeat(collect(1:R:(R*C)) .+ cfg["nin"] .- 1, 1, R)'
    genes[:, :, 1] .*= maxs
    genes[:, :, 2] .*= maxs
    genes[:, :, 3] .*= length(cfg["functions"])
    genes = Int8.(ceil.(genes))
    outputs = Int8.(ceil.(chromosome[(R*C*3+1):end] .* (R * C + cfg["nin"])))
    Individual(cfg, chromosome, genes, outputs)
end

function Individual(cfg::Dict)::Individual
    chromosome = rand(cfg["rows"] * cfg["columns"] * 3 + cfg["nout"])
    Individual(cfg, chromosome)
end
