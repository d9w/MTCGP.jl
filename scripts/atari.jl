using MTCGP
using Cambrian
using ArcadeLearningEnvironment
using ArgParse
import Random

include("game.jl")

```
Playing Atari games using MTCGP

```

s = ArgParseSettings()
@add_arg_table s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/atari.yaml"
    "--game"
    help = "game rom name"
    default = "centipede"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
end
args = parse_args(ARGS, s)

cfg = get_config(args["cfg"])
cfg["game"] = args["game"]
Random.seed!(args["seed"])

function play_atari(ind::MTCGPInd; seed=0, max_frames=18000)
    game = Game(cfg["game"], seed)
    reward = 0.0
    frames = 0
    while ~game_over(game.ale)
        output = mean_process(ind, get_rgb(game))
        action = game.actions[argmax(output)]
        reward += act(game.ale, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(game)
    [reward]
end

function get_params()
    game = Game(cfg["game"], 0)
    nin = 3 # r g b
    nout = length(game.actions)
    close!(game)
    nin, nout
end

function populate(evo::Cambrian.Evolution)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    Cambrian.oneplus_populate!(evo; mutation=mutation, reset_expert=true)
end

function evaluate(evo::Cambrian.Evolution)
    fit = i::MTCGPInd->play_atari(i; seed=evo.gen, max_frames=min(10*evo.gen, 18000))
    Cambrian.fitness_evaluate!(evo; fitness=fit)
end

cfg["n_in"], cfg["n_out"] = get_params()

e = Cambrian.Evolution(MTCGPInd, cfg; id=string(cfg["game"], "_", args["seed"]),
                       populate=populate,
                       evaluate=evaluate)
Cambrian.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
