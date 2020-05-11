module MTCGP

import YAML
import Statistics
import StatsBase
import Images
import ImageFiltering
import ImageMorphology
import ImageTransformations
import Cambrian
import JSON

include("util.jl")
include("functions.jl")
include("config.jl")
include("individual.jl")
include("process.jl")
include("evolution.jl")

end
