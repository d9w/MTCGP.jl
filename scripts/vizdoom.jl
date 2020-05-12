using MTCGP
using Cambrian
using PyCall
using ArgParse
import Random

```
Playing VizDoom games using classic CGP on RAM values
```

s = ArgParseSettings()
@add_arg_table s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/atari.yaml"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
end
args = parse_args(ARGS, s)

cfg = get_config(args["cfg"])
Random.seed!(args["seed"])

cfg["n_in"] = 3
cfg["n_out"] = 32

vzd = pyimport("vizdoom")

function get_game(map::String="map01")
    game = vzd.DoomGame()
    game.set_doom_map(map)
    game.add_available_button(vzd.Button.MOVE_LEFT)
    game.add_available_button(vzd.Button.MOVE_RIGHT)
    game.add_available_button(vzd.Button.MOVE_FORWARD)
    game.add_available_button(vzd.Button.MOVE_BACKWARD)
    game.add_available_button(vzd.Button.ATTACK)
    game.set_window_visible(false)
    game.init()
    game.new_episode()
    game
end

py"""
import itertools as it
def act(game, a_id):
    actions = [list(a) for a in it.product([0, 1], repeat=5)]
    return game.make_action(actions[a_id])
"""

function play_vizdoom(ind::MTCGPInd; seed=0, max_frames=1000)
    game = get_game()
    reward = 0.0
    frames = 0
    while ~game.is_episode_finished()
        screen = game.get_state().screen_buffer ./ 256
        inputs = [screen[i, :, :] for i in 1:3]
        action = argmax(mean_process(ind, inputs)) - 1
        reward += py"act"(game, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    game.close()
    [reward]
end

function populate(evo::Cambrian.Evolution)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    Cambrian.oneplus_populate!(evo; mutation=mutation, reset_expert=false) # true
end

function evaluate(evo::Cambrian.Evolution)
    fit = i::MTCGPInd->play_vizdoom(i; max_frames=min(10*evo.gen, 18000)) #seed=evo.gen,
    Cambrian.fitness_evaluate!(evo; fitness=fit)
end

e = Cambrian.Evolution(MTCGPInd, cfg; id=string("vizdoom_", args["seed"]),
                       populate=populate,
                       evaluate=evaluate)
Cambrian.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
