export get_config

function load_functions(funs::Dict)
    newfuns = []
    for k in keys(funs)
        if isdefined(Config, parse(k))
            debug("Loading functions: $k is already defined, skipping")
        else
            if length(funs[k])==1
                sgen(k, funs[k][1], funs[k][1], funs[k][1], funs[k][1])
            elseif length(funs[k])==2
                sgen(k, funs[k][1], funs[k][1], funs[k][2], funs[k][2])
            else
                sgen(k, funs[k][1], funs[k][2], funs[k][3], funs[k][4])
            end
            append!(newfuns, [k])
        end
    end
    [eval(parse(k)) for k in newfuns]
end

function get_config(config::Dict)
    for k in keys(config)
        if k == "functions"
            append!(functions, load_functions(config["functions"]))
        else
            if config[k] != nothing
                eval(parse(string(k, "=", config[k])))
            end
        end
    end
end

function get_config(file::String)
    get_config(YAML.load_file(file))
end
