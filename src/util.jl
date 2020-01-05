export find_active

function recur_active!(active::BitArray, ind::Int8, xs::Array{Int8},
                       ys::Array{Int8}, fs::Array{Int8},
                       two_arity::BitArray)::Nothing
    if ind > 0 && ~active[ind]
        active[ind] = true
        recur_active!(active, xs[ind], xs, ys, fs, two_arity)
        if two_arity[fs[ind]]
            recur_active!(active, ys[ind], xs, ys, fs, two_arity)
        end
    end
end

function find_active(cfg::Dict, genes::Array{Int8},
                     outputs::Array{Int8})::BitArray
    R = cfg["rows"]
    C = cfg["columns"]
    active = falses(R, C)
    xs = genes[:, :, 1] .- Int8(cfg["nin"])
    ys = genes[:, :, 2] .- Int8(cfg["nin"])
    fs = genes[:, :, 3]
    for i in eachindex(outputs)
        recur_active!(active, outputs[i] - Int8(cfg["nin"]), xs, ys, fs,
                      cfg["two_arity"])
    end
    active
end
