@everywhere using MTCGP
@everywhere using PyCall
@everywhere using Darwin
@everywhere using ArgParse
@everywhere import Random
@everywhere import Formatting
@everywhere import Base.GC

@everywhere function init()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--cfg"
        help = "configuration script"
        default = "cfg/gym.yaml"
        "--env"
        help = "environment"
        default = "HalfCheetahBulletEnv-v0"
        "--seed"
        help = "random seed"
        arg_type = Int
        default = 0
        "--dreward"
        help = "use dreward slope"
        action = :store_true
    end
    args = parse_args(ARGS, s)

    cfg = get_config(args["cfg"])

    pybullet_envs = pyimport("pybullet_envs")
    gym = pyimport("gym")
    cfg["env"] = args["env"]
    env = gym.make(cfg["env"])
    cfg["n_out"] = length(env.action_space.sample())
    cfg["n_in"] = length(env.observation_space.sample())
    dr = args["dreward"]
    seed = args["seed"]
    Random.seed!(seed)
    cfg, gym, seed, dr
end

@everywhere cfg, gym, seed, dr = init()

@everywhere function play_env(ind::MTCGPInd; seed::Int64=0, dreward::Float64=-Inf)
    env = gym.make(cfg["env"])
    env.seed(seed)
    obs = env.reset()
    total_reward = 0.0
    done = false
    max_obs = 2*pi
    nsteps = 0

    while ~done
        action = process(ind, obs ./ max_obs)
        obs, reward, done, _ = env.step(action)
        newmax = maximum(abs.(obs))
        if newmax > max_obs
            println("Increased max_obs from ", max_obs, " to ", newmax)
            max_obs = newmax
        end
        total_reward += reward
        nsteps += 1
        if mod(nsteps, 100) == 0
            if (total_reward / nsteps) < dreward
                done = true
                break
            end
        end
    end
    env.close()
    env = nothing
    Base.GC.gc()
    [total_reward, nsteps]
end

@everywhere function populate(evo::Darwin.Evolution)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    Darwin.oneplus_populate!(evo; mutation=mutation)
end

@everywhere function evaluate(evo::Darwin.Evolution)
    if evo.text == ""
        nsteps, dreward, eval_fit = 0, -Inf, -Inf
    else
        nsteps, dreward, eval_fit = Meta.parse.(split(evo.text, " "))
    end
    fit = i::MTCGPInd->play_env(i, seed=evo.gen, dreward=dreward)
    Darwin.distributed_evaluate!(evo; fitness=fit)
    for i in eachindex(evo.population)
        nsteps += evo.population[i].fitness[2]
        d = evo.population[i].fitness[1] / evo.population[i].fitness[2]
        if d > dreward
            dreward = d
            # evaluation fitness
            eval_fit = play_env(evo.population[i]; seed=0, dreward=-Inf)[1]
        end
    end
    evo.text = Formatting.format("{1:e} {2:e} {3:e}",
                                 nsteps, dreward, eval_fit)
    evo
end

e = Darwin.Evolution(MTCGPInd, cfg; id=string(cfg["env"], "_", seed),
                     populate=populate,
                     evaluate=evaluate)
Darwin.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
