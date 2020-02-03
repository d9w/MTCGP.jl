@everywhere using MTCGP
@everywhere using PyCall
@everywhere using Darwin
@everywhere using ArgParse
@everywhere import Distances
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
        default = "AntBulletEnv-v0"
        "--seed"
        help = "random seed"
        arg_type = Int
        default = 0
    end
    args = parse_args(ARGS, s)

    cfg = get_config(args["cfg"])

    pybullet_envs = pyimport("pybullet_envs")
    gym = pyimport("gym")
    cfg["env"] = args["env"]
    env = gym.make(cfg["env"])
    cfg["n_out"] = length(env.action_space.sample())
    cfg["n_in"] = length(env.observation_space.sample())
    seed = args["seed"]
    Random.seed!(seed)
    cfg, seed
end

@everywhere cfg, seed = init()

@everywhere function play_env(ind::MTCGPInd; seed::Int64=0)
    pybullet_envs = pyimport("pybullet_envs")
    gym = pyimport("gym")
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
    end
    x, y, z = env.robot.body_xyz
    env.close()
    env = nothing
    Base.GC.gc()
    # [total_reward, nsteps]
    [x, y, z, total_reward]
end

@everywhere function populate(evo::Darwin.Evolution)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    Darwin.oneplus_populate!(evo; mutation=mutation)
end

@everywhere function evaluate(evo::Darwin.Evolution)
    fit = i::MTCGPInd->play_env(i, seed=evo.gen)
    Darwin.distributed_evaluate!(evo; fitness=fit)
    archive = evo.cfg["archive"]
    max_reward = -Inf
    for i in eachindex(evo.population)
        fit = evo.population[i].fitness
        if fit[4] > max_reward
            max_reward = fit[4]
        end
        end_pos = fit[1:3]
        novelty = 0.0
        if length(archive) > 0
            novelty = minimum([Distances.euclidean(end_pos, i) for i in archive])
        end
        if novelty > 1e-2 || length(archive) == 0
            push!(archive, end_pos)
        end
        evo.population[i].fitness .= novelty
    end
    evo.text = Formatting.format("{1:e}", max_reward)
    evo
end

e = Darwin.Evolution(MTCGPInd, cfg; id=string(cfg["env"], "_", seed),
                     populate=populate,
                     evaluate=evaluate)
e.cfg["archive"] = Array{Array{Float64}}(undef, 0)
Darwin.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
