using MTCGP
import MLDatasets
import Cambrian
import Random

cfg = get_config("cfg/mnist.yaml")


function data_setup()
    train_x, train_y = MLDatasets.MNIST.traindata()
    X = Array{Array{Float64}}(undef, 1, size(train_x, 3))
    for i in 1:size(train_x, 3)
        X[1, i] = Float64.(train_x[:, :, 1])
    end
    r = train_y
    inds = r .<= 1
    #Y = zeros(maximum(r)+1, size(X, 2))
    Y = zeros(maximum(r)+1, size(X, 2))
    for i in eachindex(r)
        Y[r[i]+1, i] = 1.0
    end
    X[:, inds], Y[1:2, inds]
end

X, Y = data_setup()

function evaluate(ind::MTCGP.MTCGPInd)
    accuracy = 0.0
    data_inds = Random.randperm(size(X, 2))
    for i in 1:100
        out = MTCGP.mean_process(ind, X[:, data_inds[i]])
        if argmax(out) == argmax(Y[:, data_inds[i]])
            accuracy += 1
        end
    end
    accuracy
end

# test_x,  test_y  = MLDatasets.MNIST.testdata()

seed = 200
Random.seed!(seed)

n_evos = 20
evolutions = Array{Cambrian.Evolution}(undef, n_evos)
experts = Array{MTCGPInd}(undef, n_evos)
for i in eachindex(experts)
    experts[i] = MTCGPInd(cfg)
end

function exchange_experts(e::Cambrian.Evolution; n_experts=5)
    append!(e.population, experts[Random.randperm(n_evos)[1:n_experts]])
    # append!(e.population, sort(experts; rev=true)[1:n_experts])
    println([i.fitness[1] for i in e.population])
end

for evo in eachindex(evolutions)
    e = Cambrian.Evolution(MTCGPInd, cfg; id=string("mnist", seed+evo),
                         generation=exchange_experts)
    mutation = i::MTCGPInd->goldman_mutate(cfg, i)
    e.populate = x::Cambrian.Evolution->Cambrian.oneplus_populate!(
        x; mutation=mutation)
    #e.evaluate = x::Cambrian.Evolution->Cambrian.fitness_evaluate!(
    #    x; fitness=evaluate)
    e.evaluate = x::Cambrian.Evolution->Cambrian.lexicase_evaluate!(
        x, X, Y, MTCGP.mean_interpret; seed=(seed+evo)*x.gen, verify_best=false)
    evolutions[evo] = e
end

for step in 1:cfg["n_gen"]
    best_fit = 0.0
    for evo in eachindex(evolutions)
        Cambrian.step!(evolutions[evo])
        experts[evo] = copy(sort(evolutions[evo].population)[end])
        if experts[evo].fitness[1] > best_fit
            best_fit = experts[evo].fitness[1]
        end
    end
    println(step, " ", best_fit)
    # Cambrian.run!(e)
    # best = sort(e.population)[end]
    # println("Final fitness: ", best.fitness[1])
end
