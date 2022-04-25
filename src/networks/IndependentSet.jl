"""
    IndependentSet{CT<:AbstractEinsum,WT<:Union{NoWeight, Vector}} <: GraphProblem
    IndependentSet(graph; weights=NoWeight(), openvertices=(),
                 optimizer=GreedyMethod(), simplifier=nothing)

The [independent set problem](https://psychic-meme-f4d866f8.pages.github.io/dev/tutorials/IndependentSet.html) in graph theory.
In the constructor, `weights` are the weights of vertices.
`openvertices` specifies labels for the output tensor.
`optimizer` and `simplifier` are for tensor network optimization, check [`optimize_code`](@ref) for details.
"""
struct IndependentSet{CT<:AbstractEinsum,WT<:Union{NoWeight, Vector}} <: GraphProblem
    code::CT
    graph::SimpleGraph{Int}
    weights::WT
    fixedvertices::Dict{Int,Int}
end

function IndependentSet(g::SimpleGraph; weights=NoWeight(), openvertices=(), fixedvertices=Dict{Int,Int}(), optimizer=GreedyMethod(), simplifier=nothing)
    @assert weights isa NoWeight || length(weights) == nv(g)
    rawcode = EinCode([[[i] for i in Graphs.vertices(g)]..., # labels for vertex tensors
                       [[minmax(e.src,e.dst)...] for e in Graphs.edges(g)]...], collect(Int, openvertices))  # labels for edge tensors
    code = _optimize_code(rawcode, uniformsize_fix(rawcode, 2, fixedvertices), optimizer, simplifier)
    IndependentSet(code, g, weights, fixedvertices)
end

flavors(::Type{<:IndependentSet}) = [0, 1]
get_weights(gp::IndependentSet, i::Int) = [0, gp.weights[i]]
terms(gp::IndependentSet) = getixsv(gp.code)[1:nv(gp.graph)]
labels(gp::IndependentSet) = [1:nv(gp.graph)...]
fixedvertices(gp::IndependentSet) = gp.fixedvertices

# generate tensors
function generate_tensors(x::T, gp::IndependentSet) where T
    nv(gp.graph) == 0 && return []
    ixs = getixsv(gp.code)
    # we only add labels at vertex tensors
    return select_dims(vcat(add_labels!([misv(Ref(x) .^ get_weights(gp, i)) for i=1:nv(gp.graph)], ixs[1:nv(gp.graph)], labels(gp)),
            [misb(T, length(ix)) for ix in ixs[nv(gp.graph)+1:end]] # if n!=2, it corresponds to set packing problem.
    ), ixs, fixedvertices(gp))
end

function misb(::Type{T}, n::Integer=2) where T
    res = zeros(T, fill(2, n)...)
    res[1] = one(T)
    for i=1:n
        res[1+1<<(i-1)] = one(T)
    end
    return res
end
misv(vals) = vals

"""
    mis_compactify!(tropicaltensor)

Compactify tropical tensor for maximum independent set problem. It will eliminate
some entries by setting them to zero, by the criteria that removing these entry
does not change the MIS size of its parent graph (reference to be added).
"""
function mis_compactify!(a::AbstractArray{T}) where T <: TropicalTypes
	for (ind_a, val_a) in enumerate(a)
		for (ind_b, val_b) in enumerate(a)
			bs_a = ind_a - 1
			bs_b = ind_b - 1
			@inbounds if bs_a != bs_b && val_a <= val_b && (bs_b & bs_a) == bs_b
				a[ind_a] = zero(T)
			end
		end
	end
	return a
end

"""
    is_independent_set(g::SimpleGraph, config)

Return true if `config` (a vector of boolean numbers as the mask of vertices) is an independent set of graph `g`.
"""
is_independent_set(g::SimpleGraph, config) = !any(e->config[e.src] == 1 && config[e.dst] == 1, edges(g))
