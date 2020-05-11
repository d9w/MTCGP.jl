export Node, MTCGPInd
import Base.copy, Base.String, Base.show, Base.summary

function null(args...)::Nothing
    nothing
end

struct Node
    x::Int16
    y::Int16
    f::Function
    active::Bool
end

struct MTCGPInd <: Cambrian.Individual
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
    buffer .= 0.0
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

function MTCGPInd(cfg::Dict, ind::String)::MTCGPInd
    dict = JSON.parse(ind)
    MTCGPInd(cfg, Array{Float64}(dict["chromosome"]))
end

function copy(n::Node)
    Node(n.x, n.y, n.f, n.active)
end

function copy(ind::MTCGPInd)
    buffer = Array{MType}(nothing, length(ind.buffer))
    nodes = Array{Node}(undef, length(ind.nodes))
    for i in eachindex(ind.nodes)
        nodes[i] = copy(ind.nodes[i])
    end
    MTCGPInd(copy(ind.chromosome), copy(ind.genes), copy(ind.outputs),
             nodes, buffer, copy(ind.fitness))
end

function String(n::Node)
    JSON.json(n)
end

function String(ind::MTCGPInd)
    JSON.json(Dict("chromosome"=>ind.chromosome, "fitness"=>ind.fitness))
end

function get_active_nodes(ind::MTCGPInd)
    ind.nodes[[n.active for n in ind.nodes]]
end

function show(io::IO, ind::MTCGPInd)
    print(io, String(ind))
end

function summary(io::IO, ind::MTCGPInd)
    print(io, string("MTCGPInd(", get_active_nodes(ind), ", ",
                     findall([n.active for n in ind.nodes]), ", ",
                     ind.outputs, " ,",
                     ind.fitness, ")"))
end
