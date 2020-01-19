using MTCGP
import MLDatasets
import Darwin
import Random

cfg = get_config("cfg/mnist.yaml")


function data_setup()
    train_x, train_y = MLDatasets.MNIST.traindata()
    X = Array{Array{Float64}}(undef, 1, size(train_x, 3))
    for i in 1:size(train_x, 3)
        X[1, i] = Float64.(train_x[:, :, 1])
    end
    r = train_y
    Y = zeros(maximum(r)+1, size(X, 2))
    for i in eachindex(r)
        Y[r[i]+1, i] = 1.0
    end
    X, Y
end

X, Y = data_setup()

# test_x,  test_y  = MLDatasets.MNIST.testdata()

seed = 111
Random.seed!(seed)

e = Darwin.Evolution(MTCGPInd, cfg; id=string("mnist", seed))
mutation = i::MTCGPInd->goldman_mutate(cfg, i)
e.populate = x::Darwin.Evolution->Darwin.oneplus_populate!(
    x; mutation=mutation)
e.evaluate = x::Darwin.Evolution->Darwin.lexicase_evaluate!(
    x, X, Y, MTCGP.mean_interpret)

Darwin.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
