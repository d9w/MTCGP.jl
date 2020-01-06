export mutate, goldman_mutate

function mutate(cfg::Dict, ind::Individual)::Individual
    chromosome = copy(ind.chromosome)
    chance = rand(length(chromosome))
    ngenes = cfg["rows"]*cfg["columns"]*3
    change = [chance[1:ngenes] .<= cfg["mutation"];
              chance[(ngenes+1):end] .<= cfg["output_mutation"]]
    chromosome[change] = rand(sum(change))
    Individual(cfg, chromosome)
end

function goldman_mutate(cfg::Dict, ind::Individual)::Individual
    changed = false
    while !changed
        global child = mutate(cfg, ind)
        if any(ind.outputs != child.outputs)
            changed = true
            break
        else
            for i in eachindex(ind.nodes)
                if ind.nodes[i].active
                    if child.nodes[i].active
                        if (ind.nodes[i].f != child.nodes[i].f
                            || ind.nodes[i].x != child.nodes[i].x
                            || ind.nodes[i].y != child.nodes[i].y)
                            changed = true
                            break
                        end
                    else
                        changed = true
                        break
                    end
                end
            end
        end
    end
    child
end

