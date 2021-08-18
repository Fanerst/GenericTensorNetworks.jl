module GraphTensorNetworks

using OMEinsumContractionOrders: OMEinsum
using Core: Argument
using TropicalGEMM, TropicalNumbers
using OMEinsum
using OMEinsum: flatten, timespace_complexity
using LightGraphs

export timespace_complexity

# patches for OMEinsum
OMEinsum.asarray(x, ::AbstractArray) = fill(x)
OMEinsum.dynamic_einsum(::EinCode{ixs, iy}, xs; kwargs...) where {ixs, iy} = dynamic_einsum(ixs, xs, iy; kwargs...)

project_relative_path(xs...) = normpath(joinpath(dirname(dirname(pathof(@__MODULE__))), xs...))

include("arithematics.jl")
include("networks.jl")
include("graph_polynomials.jl")
include("configurations.jl")
include("graphs.jl")
include("bounding.jl")
include("viz.jl")
include("interfaces.jl")

using Requires
function __init__()
    @require CUDA="052768ef-5323-5732-b1bb-66c8b64840ba" include("cuda.jl")
end

end