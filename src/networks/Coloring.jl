"""
    Coloring{K,CT<:AbstractEinsum} <: GraphProblem
    Coloring{K}(graph; openvertices=(), optimizer=GreedyMethod(), simplifier=nothing)

[Vertex Coloring](https://psychic-meme-f4d866f8.pages.github.io/dev/tutorials/Coloring.html) problem.
`optimizer` and `simplifier` are for tensor network optimization, check `optimize_code` for details.
"""
struct Coloring{K,CT<:AbstractEinsum} <: GraphProblem
    code::CT
    nv::Int
end
Coloring{K}(code::ET, nv::Int) where {K,ET<:AbstractEinsum} = Coloring{K,ET}(code, nv)
# same network layout as independent set.
function Coloring{K}(g::SimpleGraph; openvertices=(), optimizer=GreedyMethod(), simplifier=nothing) where K
    rawcode = EinCode(([[i] for i in Graphs.vertices(g)]..., # labels for vertex tensors
                       [[minmax(e.src,e.dst)...] for e in Graphs.edges(g)]...), collect(Int, openvertices))  # labels for edge tensors
    code = _optimize_code(rawcode, uniformsize(rawcode, 2), optimizer, simplifier)
    Coloring{K}(code, nv(g))
end

flavors(::Type{<:Coloring{K}}) where K = collect(0:K-1)
symbols(c::Coloring{K}) where K = [i for i=1:c.nv]
get_weights(::Coloring{K}, sym) where K = ones(Int, K)

# `fx` is a function defined on symbols, it returns a vector of elements, the size of vector is same as the number of flavors (or the bond dimension).
function generate_tensors(fx, c::Coloring{K}) where K
    ixs = getixsv(c.code)
    T = eltype(fx(ixs[1][1]))
    return map(1:length(ixs)) do i
        i <= c.nv ? coloringv(fx(ixs[i][1])) : coloringb(T, K)
    end
end

# coloring bond tensor
function coloringb(::Type{T}, k::Int) where T
    x = ones(T, k, k)
    for i=1:k
        x[i,i] = zero(T)
    end
    return x
end
# coloring vertex tensor
coloringv(vals::Vector{T}) where T = vals

