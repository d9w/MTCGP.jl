export Node, MTCGPInd

function null(args...)::Nothing
    nothing
end

struct Node
    x::Int16
    y::Int16
    f::Function
    active::Bool
end

struct MTCGPInd <: Darwin.Individual
    chromosome::Array{Float64}
    genes::Array{Int16}
    outputs::Array{Int16}
    nodes::Array{Node}
    buffer::Array{MType}
    fitness::Array{Float64}
end

function MTCGPInd(cfg::Dict, chromosome::Array{Float64}, genes::Array{Int16},
                    outputs::Array{Int16})::MTCGPInd
    R = cfg["rows"]
    C = cfg["columns"]
    nodes = Array{Node}(undef, R * C + cfg["n_in"])
    for i in 1:cfg["n_in"]
        nodes[i] = Node(0, 0, null, false)
    end
    i = cfg["n_in"]
    active = find_active(cfg, genes, outputs)
    for y in 1:C
        for x in 1:R
            i += 1
            nodes[i] = Node(genes[x, y, 1], genes[x, y, 2],
                            cfg["functions"][genes[x, y, 3]],
                            active[x, y])
        end
    end
    buffer = Array{MType}(nothing, R * C + cfg["n_in"])
    fitness = -Inf .* ones(cfg["d_fitness"])
    MTCGPInd(chromosome, genes, outputs, nodes, buffer, fitness)
end

function MTCGPInd(cfg::Dict, chromosome::Array{Float64})::MTCGPInd
    R = cfg["rows"]
    C = cfg["columns"]
    genes = reshape(chromosome[1:(R*C*3)], R, C, 3)
    maxs = repeat(collect(1:R:(R*C)) .+ cfg["n_in"] .- 1, 1, R)'
    genes[:, :, 1] .*= maxs
    genes[:, :, 2] .*= maxs
    genes[:, :, 3] .*= length(cfg["functions"])
    genes = Int16.(ceil.(genes))
    outputs = Int16.(ceil.(chromosome[(R*C*3+1):end] .* (R * C + cfg["n_in"])))
    MTCGPInd(cfg, chromosome, genes, outputs)
end

function MTCGPInd(cfg::Dict)::MTCGPInd
    chromosome = rand(cfg["rows"] * cfg["columns"] * 3 + cfg["n_out"])
    MTCGPInd(cfg, chromosome)
end
