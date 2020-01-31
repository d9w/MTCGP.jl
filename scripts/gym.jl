using MTCGP
using PyCall
using Darwin
import Random

cfg = get_config("cfg/gym.yaml")

pybullet_envs = pyimport("pybullet_envs")
gym = pyimport("gym")
env = gym.make(cfg["env"])
cfg["n_out"] = length(env.action_space.sample())
cfg["n_in"] = length(env.observation_space.sample())
max_obs = 2*pi
seed = 110
Random.seed!(seed)

function play_env(ind::MTCGPInd; seed::Int64=0)
    #env = gym.make(cfg["env"])
    env.seed(seed)
    obs = env.reset()
    total_reward = 0.0
    done = false

    while ~done
        action = process(ind, obs ./ max_obs)
        obs, reward, done, _ = env.step(action)
        total_reward += reward
    end
    [total_reward]
end

function gen_fitness(seed::Int64)
    i::MTCGPInd->play_env(i, seed=seed)
end

function populate(evo::Darwin.Evolution)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    Darwin.oneplus_populate!(evo; mutation=mutation)
end

function evaluate(evo::Darwin.Evolution)
    Darwin.fitness_evaluate!(evo; fitness=play_env)
end

e = Darwin.Evolution(MTCGPInd, cfg; id=string(cfg["env"], "_", seed),
                     populate=populate,
                     evaluate=evaluate)
Darwin.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
