"""
    GraphProblem

The abstract base type of graph problems.
"""
abstract type GraphProblem end

struct NoWeight end
Base.getindex(::NoWeight, i) = 1
Base.eltype(::NoWeight) = Int

######## Interfaces for graph problems ##########
"""
    get_weights(problem::GraphProblem, sym)

The weights for the degree of freedom specified by `sym` of the graph problem, where `sym` is a symbol.
In graph polynomial, integer weights are the orders of `x`.
"""
function get_weights end

"""
    labels(problem::GraphProblem)

The labels of a graph problem is defined as the degrees of freedoms in the graph problem.
e.g. for the maximum independent set problems, they are the indices of vertices: 1, 2, 3...,
while for the max cut problem, they are the edges.
"""
function labels end

"""
    terms(problem::GraphProblem)

The terms of a graph problem is defined as the tensor labels that defining local energies (or weights) in the graph problem.
e.g. for the maximum independent set problems, they are the vertex-tensor labels: [1], [2], [3]...
The weight of a term is same as the power of `x` in the graph polynomial.
"""
function terms end

"""
    flavors(::Type{<:GraphProblem})

It returns a vector of integers as the flavors of a degree of freedom.
Its size is the same as the degree of freedom on a single vertex/edge.
"""
flavors(::GT) where GT<:GraphProblem = flavors(GT)

"""
    nflavor(::Type{<:GraphProblem})

Bond size is equal to the number of flavors.
"""
nflavor(::Type{GT}) where GT = length(flavors(GT))
nflavor(::GT) where GT<:GraphProblem = nflavor(GT)

"""
    generate_tensors(func, problem::GraphProblem)

Generate a vector of tensors as the inputs of the tensor network contraction code `problem.code`.
`func` is a function to customize the tensors.
`func(symbol)` returns a vector of elements, the length of which is same as the number of flavors.

Example
--------------------------
The following code gives your the maximum independent set size
```jldoctest
julia> using Graphs, GenericTensorNetworks

julia> gp = IndependentSet(smallgraph(:petersen));

julia> getixsv(gp.code)
25-element Vector{Vector{Int64}}:
 [1]
 [2]
 [3]
 [4]
 [5]
 [6]
 [7]
 [8]
 [9]
 [10]
 ⋮
 [3, 8]
 [4, 5]
 [4, 9]
 [5, 10]
 [6, 8]
 [6, 9]
 [7, 9]
 [7, 10]
 [8, 10]

julia> gp.code(GenericTensorNetworks.generate_tensors(Tropical(1.0), gp)...)
0-dimensional Array{TropicalF64, 0}:
4.0ₜ
```
"""
generate_tensors(::Type{GT}) where GT = length(flavors(GT))

# requires field `code`

include("IndependentSet.jl")
include("MaximalIS.jl")
include("MaxCut.jl")
include("Matching.jl")
include("Coloring.jl")
include("PaintShop.jl")
include("Satisfiability.jl")
include("DominatingSet.jl")
include("SetPacking.jl")
include("SetCovering.jl")

# forward the time, space and readwrite complexity
OMEinsum.timespacereadwrite_complexity(gp::GraphProblem) = timespacereadwrite_complexity(gp.code, uniformsize(gp.code, nflavor(gp)))

# contract the graph tensor network
function contractx(gp::GraphProblem, x; usecuda=false)
    @debug "generating tensors for x = `$x` ..."
    xs = generate_tensors(x, gp)
    @debug "contracting tensors ..."
    if usecuda
        gp.code([CuArray(x) for x in xs]...)
    else
        gp.code(xs...)
    end
end

# multiply labels vectors to the generate tensor.
add_labels!(tensors::AbstractVector{<:AbstractArray}, ixs, labels) = tensors

const SetPolyNumbers{T} = Union{Polynomial{T}, TruncatedPoly{K,T} where K, CountingTropical{TV,T} where TV} where T<:AbstractSetNumber
function add_labels!(tensors::AbstractVector{<:AbstractArray{T}}, ixs, labels, fix_config=Dict()) where T <: Union{AbstractSetNumber, SetPolyNumbers, ExtendedTropical{K,T} where {K,T<:SetPolyNumbers}}
    for (t, ix) in zip(tensors, ixs)
        for (dim, l) in enumerate(ix)
            index = findfirst(==(l), labels)
            config = l ∈ keys(fix_config) ? (fix_config[l]+1:fix_config[l]+1) : (1:size(t, dim))
            v = [_onehotv(T, index, k-1) for k=config]#1:size(t, dim)]
            t .*= reshape(v, ntuple(j->dim==j ? length(v) : 1, ndims(t)))
        end
    end
    return tensors
end

# TODOs:
# 1. Dominating set
# \exists x_i,\ldots,x_K \forall y\left[\bigwedge_{i=1}^{K}(y=x_i\wedge \textbf{adj}(y, x_i))\right]
# 2. Polish reading data
#     * consistent configuration assign of max-cut
# 3. Support transverse field in max-cut