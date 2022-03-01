using Polynomials: Polynomial
using TropicalNumbers: Tropical, CountingTropical
using Mods, Primes
using Base.Cartesian
import AbstractTrees: children, printnode, print_tree

@enum TreeTag LEAF SUM PROD ZERO

# pirate
Base.abs(x::Mod) = x
Base.isless(x::Mod{N}, y::Mod{N}) where N = mod(x.val, N) < mod(y.val, N)


"""
    is_commutative_semiring(a::T, b::T, c::T) where T

Check if elements `a`, `b` and `c` satisfied the commutative semiring requirements.
```math
\\begin{align*}
(a \\oplus b) \\oplus c = a \\oplus (b \\oplus c) & \\hspace{5em}\\triangleright\\text{commutative monoid \$\\oplus\$ with identity \$\\mathbb{0}\$}\\\\
a \\oplus \\mathbb{0} = \\mathbb{0} \\oplus a = a &\\\\
a \\oplus b = b \\oplus a &\\\\
&\\\\
(a \\odot b) \\odot c = a \\odot (b \\odot c)  &   \\hspace{5em}\\triangleright \\text{commutative monoid \$\\odot\$ with identity \$\\mathbb{1}\$}\\\\
a \\odot  \\mathbb{1} =  \\mathbb{1} \\odot a = a &\\\\
a \\odot b = b \\odot a &\\\\
&\\\\
a \\odot (b\\oplus c) = a\\odot b \\oplus a\\odot c  &  \\hspace{5em}\\triangleright \\text{left and right distributive}\\\\
(a\\oplus b) \\odot c = a\\odot c \\oplus b\\odot c &\\\\
&\\\\
a \\odot \\mathbb{0} = \\mathbb{0} \\odot a = \\mathbb{0}
\\end{align*}
```
"""
function is_commutative_semiring(a::T, b::T, c::T) where T
    # +
    if (a + b) + c != a + (b + c)
        @debug "(a + b) + c != a + (b + c)"
        return false
    end
    if !(a + zero(T) == zero(T) + a == a)
        @debug "!(a + zero(T) == zero(T) + a == a)"
        return false
    end
    if a + b != b + a
        @debug "a + b != b + a"
        return false
    end
    # *
    if (a * b) * c != a * (b * c)
        @debug "(a * b) * c != a * (b * c)"
        return false
    end
    if !(a * one(T) == one(T) * a == a)
        @debug "!(a * one(T) == one(T) * a == a)"
        return false
    end
    if a * b != b * a
        @debug "a * b != b * a"
        return false
    end
    # more
    if a * (b+c) != a*b + a*c
        @debug "a * (b+c) != a*b + a*c"
        return false
    end
    if (a+b) * c != a*c + b*c
        @debug "(a+b) * c != a*c + b*c"
        return false
    end
    if !(a * zero(T) == zero(T) * a == zero(T))
        @debug "!(a * zero(T) == zero(T) * a == zero(T))"
        return false
    end
    if !(a * zero(T) == zero(T) * a == zero(T))
        @debug "!(a * zero(T) == zero(T) * a == zero(T))"
        return false
    end
    return true
end

######################## Truncated Polynomial ######################
# TODO: store orders to support non-integer weights
# (↑) Maybe not so nessesary, no use case for counting degeneracy when using floating point weights.
"""
    TruncatedPoly{K,T,TO} <: Number
    TruncatedPoly(coeffs::Tuple, maxorder)

Polynomial truncated to largest `K` orders. `T` is the coefficients type and `TO` is the orders type.

Example
------------------------
```jldoctest; setup=(using GraphTensorNetworks)
julia> TruncatedPoly((1,2,3), 6)
x^4 + 2*x^5 + 3*x^6

julia> TruncatedPoly((1,2,3), 6) * TruncatedPoly((5,2,1), 3)
20*x^7 + 8*x^8 + 3*x^9

julia> TruncatedPoly((1,2,3), 6) + TruncatedPoly((5,2,1), 3)
x^4 + 2*x^5 + 3*x^6
```
"""
struct TruncatedPoly{K,T,TO} <: Number
    coeffs::NTuple{K,T}
    maxorder::TO
end

"""
    Max2Poly{T,TO} = TruncatedPoly{2,T,TO}
    Max2Poly(a, b, maxorder)

A shorthand of [`TruncatedPoly`](@ref){2}.
"""
const Max2Poly{T,TO} = TruncatedPoly{2,T,TO}
Max2Poly(a, b, maxorder) = TruncatedPoly((a, b), maxorder)
Max2Poly{T,TO}(a, b, maxorder) where {T,TO} = TruncatedPoly{2,T,TO}((a, b), maxorder)

function Base.:+(a::Max2Poly, b::Max2Poly)
    aa, ab = a.coeffs
    ba, bb = b.coeffs
    if a.maxorder == b.maxorder
        return Max2Poly(aa+ba, ab+bb, a.maxorder)
    elseif a.maxorder == b.maxorder-1
        return Max2Poly(ab+ba, bb, b.maxorder)
    elseif a.maxorder == b.maxorder+1
        return Max2Poly(aa+bb, ab, a.maxorder)
    elseif a.maxorder < b.maxorder
        return b
    else
        return a
    end
end

@generated function Base.:+(a::TruncatedPoly{K}, b::TruncatedPoly{K}) where K
    quote
        if a.maxorder == b.maxorder
            return TruncatedPoly(a.coeffs .+ b.coeffs, a.maxorder)
        elseif a.maxorder > b.maxorder
            offset = a.maxorder - b.maxorder
            return TruncatedPoly((@ntuple $K i->i+offset <= $K ? a.coeffs[i] + b.coeffs[i+offset] : a.coeffs[i]), a.maxorder)
        else
            offset = b.maxorder - a.maxorder
            return TruncatedPoly((@ntuple $K i->i+offset <= $K ? b.coeffs[i] + a.coeffs[i+offset] : b.coeffs[i]), b.maxorder)
        end
    end
end

@generated function Base.:*(a::TruncatedPoly{K,T}, b::TruncatedPoly{K,T}) where {K,T}
    tupleexpr = Expr(:tuple, [K-k+1 > 1 ? Expr(:call, :+, [:(a.coeffs[$(i+k-1)]*b.coeffs[$(K-i+1)]) for i=1:K-k+1]...) : :(a.coeffs[$k]*b.coeffs[$K]) for k=1:K]...)
    quote
        maxorder = a.maxorder + b.maxorder
        TruncatedPoly($tupleexpr, maxorder)
    end
end

Base.zero(::Type{TruncatedPoly{K,T,TO}}) where {K,T,TO} = TruncatedPoly(ntuple(i->zero(T), K), zero(Tropical{TO}).n)
Base.one(::Type{TruncatedPoly{K,T,TO}}) where {K,T,TO} = TruncatedPoly(ntuple(i->i==K ? one(T) : zero(T), K), zero(TO))
Base.zero(::TruncatedPoly{K,T,TO}) where {K,T,TO} = zero(TruncatedPoly{K,T,TO})
Base.one(::TruncatedPoly{K,T,TO}) where {K,T,TO} = one(TruncatedPoly{K,T,TO})

Base.show(io::IO, x::TruncatedPoly) = show(io, MIME"text/plain"(), x)
function Base.show(io::IO, ::MIME"text/plain", x::TruncatedPoly{K}) where K
    if isinf(x.maxorder)
        print(io, 0)
    else
        printpoly(io, Polynomial([x.coeffs...], :x), offset=Int(x.maxorder-K+1))
    end
end

############################ ExtendedTropical #####################
"""
    ExtendedTropical{K,TO} <: Number
    ExtendedTropical(orders)

Extended Tropical numbers with largest `K` orders keeped,
or the [`TruncatedPoly`](@ref) without coefficients,
`TO` is the element type of orders.

Example
------------------------------
```jldoctest; setup=(using GraphTensorNetworks)
julia> x = ExtendedTropical{3}([1.0, 2, 3])
ExtendedTropical{3, Float64}([1.0, 2.0, 3.0])

julia> y = ExtendedTropical{3}([-Inf, 2, 5])
ExtendedTropical{3, Float64}([-Inf, 2.0, 5.0])

julia> x * y
ExtendedTropical{3, Float64}([6.0, 7.0, 8.0])

julia> x + y
ExtendedTropical{3, Float64}([2.0, 3.0, 5.0])

julia> one(x)
ExtendedTropical{3, Float64}([-Inf, -Inf, 0.0])

julia> zero(x)
ExtendedTropical{3, Float64}([-Inf, -Inf, -Inf])
```
"""
struct ExtendedTropical{K,TO} <: Number
    orders::Vector{TO}
end
function ExtendedTropical{K}(x::Vector{T}) where {T, K}
    @assert length(x) == K
    @assert issorted(x)
    ExtendedTropical{K,T}(x)
end
Base.:(==)(a::ExtendedTropical{K}, b::ExtendedTropical{K}) where K = all(i->a.orders[i] == b.orders[i], 1:K)

function Base.:*(a::ExtendedTropical{K,TO}, b::ExtendedTropical{K,TO}) where {K,TO}
    res = Vector{TO}(undef, K)
    return ExtendedTropical{K,TO}(sorted_sum_combination!(res, a.orders, b.orders))
end

using DataStructures: BinaryHeap
function sorted_sum_combination!(res::AbstractVector{TO}, A::AbstractVector{TO}, B::AbstractVector{TO}) where TO
    K = length(res)
    @assert length(B) == length(A) == K
    maxval = A[K] + B[K]
    ptr = K
    res[ptr] = maxval
    #queue = [(A[K]+B[K-1],K,K-1), (A[K-1]+B[K],K-1,K)]
    queue = BinaryHeap(Base.Order.Reverse, [(A[K]+B[K-1],K,K-1), (A[K-1]+B[K],K-1,K)])
    for k = 1:K-1
        (res[K-k], i, j) = pop!(queue)   # TODO: do not enumerate, use better data structures
        _push_if_not_exists!(queue, i, j-1, A, B)
        _push_if_not_exists!(queue, i-1, j, A, B)
    end
    return res
end

@inline function push_norepeat!(h::BinaryHeap, v)
    push!(h, v)
    return h
end

function _push_if_not_exists!(queue::BinaryHeap, i, j, A, B)
    @inbounds if j>=1 && i>=1
        push_norepeat!(queue, (A[i] + B[j], i, j))
    end
end

function _push_if_not_exists!(queue, i, j, A, B)
    @inbounds if j>=1 && i>=1 && !any(x->x[1] >= i && x[2] >= j, queue)
        push!(queue, (i, j, A[i] + B[j]))
    end
end

function _pop_max_sum!(queue)
    maxsum = first(queue)[3]
    maxloc = 1
    @inbounds for i=2:length(queue)
        m = queue[i][3]
        if m > maxsum
            maxsum = m
            maxloc = i
        end
    end
    @inbounds data = queue[maxloc]
    deleteat!(queue, maxloc)
    return data
end

function Base.:+(a::ExtendedTropical{K,TO}, b::ExtendedTropical{K,TO}) where {K,TO}
    res = Vector{TO}(undef, K)
    ptr1, ptr2 = K, K
    @inbounds va, vb = a.orders[ptr1], b.orders[ptr2]
    @inbounds for i=K:-1:1
        if va > vb
            res[i] = va
            if ptr1 != 1
                ptr1 -= 1
                va = a.orders[ptr1]
            end
        else
            res[i] = vb
            if ptr2 != 1
                ptr2 -= 1
                vb = b.orders[ptr2]
            end
        end
    end
    return ExtendedTropical{K,TO}(res)
end

Base.:^(a::ExtendedTropical, b::Integer) = Base.invoke(^, Tuple{ExtendedTropical, Real}, a, b)
function Base.:^(a::ExtendedTropical{K,TO}, b::Real) where {K,TO}
    if iszero(b)  # to avoid NaN
        return one(ExtendedTropical{K,promote_type(TO,typeof(b))})
    else
        return ExtendedTropical{K,TO}(a.orders .* b)
    end
end

Base.zero(::Type{ExtendedTropical{K,TO}}) where {K,TO} = ExtendedTropical{K,TO}(fill(zero(Tropical{TO}).n, K))
Base.one(::Type{ExtendedTropical{K,TO}}) where {K,TO} = ExtendedTropical{K,TO}(map(i->i==K ? one(Tropical{TO}).n : zero(Tropical{TO}).n, 1:K))
Base.zero(::ExtendedTropical{K,TO}) where {K,TO} = zero(ExtendedTropical{K,TO})
Base.one(::ExtendedTropical{K,TO}) where {K,TO} = one(ExtendedTropical{K,TO})

############################ SET Numbers ##########################
abstract type AbstractSetNumber end

"""
    ConfigEnumerator{N,S,C} <: AbstractSetNumber

Set algebra for enumerating configurations, where `N` is the length of configurations,
`C` is the size of storage in unit of `UInt64`,
`S` is the bit width to store a single element in a configuration, i.e. `log2(# of flavors)`, for bitstrings, it is `1``.

Example
----------------------
```jldoctest; setup=:(using GraphTensorNetworks)
julia> a = ConfigEnumerator([StaticBitVector([1,1,1,0,0]), StaticBitVector([1,0,0,0,1])])
{11100, 10001}

julia> b = ConfigEnumerator([StaticBitVector([0,0,0,0,0]), StaticBitVector([1,0,1,0,1])])
{00000, 10101}

julia> a + b
{11100, 10001, 00000, 10101}

julia> one(a)
{00000}

julia> zero(a)
{}
```
"""
struct ConfigEnumerator{N,S,C} <: AbstractSetNumber
    data::Vector{StaticElementVector{N,S,C}}
end

Base.length(x::ConfigEnumerator{N}) where N = length(x.data)
Base.iterate(x::ConfigEnumerator{N}) where N = iterate(x.data)
Base.iterate(x::ConfigEnumerator{N}, state) where N = iterate(x.data, state)
Base.getindex(x::ConfigEnumerator, i) = x.data[i]
Base.:(==)(x::ConfigEnumerator{N,S,C}, y::ConfigEnumerator{N,S,C}) where {N,S,C} = Set(x.data) == Set(y.data)

function Base.:+(x::ConfigEnumerator{N,S,C}, y::ConfigEnumerator{N,S,C}) where {N,S,C}
    length(x) == 0 && return y
    length(y) == 0 && return x
    return ConfigEnumerator{N,S,C}(vcat(x.data, y.data))
end

function Base.:*(x::ConfigEnumerator{L,S,C}, y::ConfigEnumerator{L,S,C}) where {L,S,C}
    M, N = length(x), length(y)
    M == 0 && return x
    N == 0 && return y
    z = Vector{StaticElementVector{L,S,C}}(undef, M*N)
    @inbounds for j=1:N, i=1:M
        z[(j-1)*M+i] = x.data[i] | y.data[j]
    end
    return ConfigEnumerator{L,S,C}(z)
end

Base.zero(::Type{ConfigEnumerator{N,S,C}}) where {N,S,C} = ConfigEnumerator{N,S,C}(StaticElementVector{N,S,C}[])
Base.one(::Type{ConfigEnumerator{N,S,C}}) where {N,S,C} = ConfigEnumerator{N,S,C}([zero(StaticElementVector{N,S,C})])
Base.zero(::ConfigEnumerator{N,S,C}) where {N,S,C} = zero(ConfigEnumerator{N,S,C})
Base.one(::ConfigEnumerator{N,S,C}) where {N,S,C} = one(ConfigEnumerator{N,S,C})
Base.show(io::IO, x::ConfigEnumerator) = print(io, "{", join(x.data, ", "), "}")
Base.show(io::IO, ::MIME"text/plain", x::ConfigEnumerator) = Base.show(io, x)

# the algebra sampling one of the configurations
"""
    ConfigSampler{N,S,C} <: AbstractSetNumber
    ConfigSampler(elements::StaticElementVector)

The algebra for sampling one configuration, where `N` is the length of configurations,
`C` is the size of storage in unit of `UInt64`,
`S` is the bit width to store a single element in a configuration, i.e. `log2(# of flavors)`, for bitstrings, it is `1``.

!!! note
    `ConfigSampler` is a **probabilistic** commutative semiring, adding two config samplers do not give you deterministic results.

Example
----------------------
```jldoctest; setup=:(using GraphTensorNetworks, Random; Random.seed!(2))
julia> ConfigSampler(StaticBitVector([1,1,1,0,0]))
ConfigSampler{5, 1, 1}(11100)

julia> ConfigSampler(StaticBitVector([1,1,1,0,0])) + ConfigSampler(StaticBitVector([1,0,1,0,0]))
ConfigSampler{5, 1, 1}(10100)

julia> ConfigSampler(StaticBitVector([1,1,1,0,0])) * ConfigSampler(StaticBitVector([0,0,0,0,1]))
ConfigSampler{5, 1, 1}(11101)

julia> one(ConfigSampler{5, 1, 1})
ConfigSampler{5, 1, 1}(00000)

julia> zero(ConfigSampler{5, 1, 1})
ConfigSampler{5, 1, 1}(11111)
```
"""
struct ConfigSampler{N,S,C} <: AbstractSetNumber
    data::StaticElementVector{N,S,C}
end

Base.:(==)(x::ConfigSampler{N,S,C}, y::ConfigSampler{N,S,C}) where {N,S,C} = x.data == y.data

function Base.:+(x::ConfigSampler{N,S,C}, y::ConfigSampler{N,S,C}) where {N,S,C}  # biased sampling: return `x`, maybe using random sampler is better.
    return randn() > 0.5 ? x : y
end

function Base.:*(x::ConfigSampler{L,S,C}, y::ConfigSampler{L,S,C}) where {L,S,C}
    ConfigSampler(x.data | y.data)
end

@generated function Base.zero(::Type{ConfigSampler{N,S,C}}) where {N,S,C}
    ex = Expr(:call, :(StaticElementVector{$N,$S,$C}), Expr(:tuple, fill(typemax(UInt64), C)...))
    :(ConfigSampler{N,S,C}($ex))
end
Base.one(::Type{ConfigSampler{N,S,C}}) where {N,S,C} = ConfigSampler{N,S,C}(zero(StaticElementVector{N,S,C}))
Base.zero(::ConfigSampler{N,S,C}) where {N,S,C} = zero(ConfigSampler{N,S,C})
Base.one(::ConfigSampler{N,S,C}) where {N,S,C} = one(ConfigSampler{N,S,C})

# tree config enumerator
# it must be mutable, otherwise the `IdDict` trick for computing the length does not work.
"""
    TreeConfigEnumerator{N,S,C} <: AbstractSetNumber

Configuration enumerator encoded in a tree, it is the most natural representation given by a sum-product network
and is often more memory efficient than putting the configurations in a vector.
`N`, `S` and `C` are type parameters from the [`StaticElementVector`](@ref){N,S,C}.

Fields
-----------------------
* `tag` is one of `ZERO`, `LEAF`, `SUM`, `PROD`.
* `data` is the element stored in a `LEAF` node.
* `left` and `right` are two operands of a `SUM` or `PROD` node.

Example
------------------------
```jldoctest; setup=:(using GraphTensorNetworks)
julia> s = TreeConfigEnumerator(bv"00111")
00111


julia> q = TreeConfigEnumerator(bv"10000")
10000


julia> x = s + q
+
├─ 00111
└─ 10000


julia> y = x * x
*
├─ +
│  ├─ 00111
│  └─ 10000
└─ +
   ├─ 00111
   └─ 10000


julia> collect(y)
4-element Vector{StaticBitVector{5, 1}}:
 00111
 10111
 10111
 10000

julia> zero(s)
∅



julia> one(s)
00000


```
"""
mutable struct TreeConfigEnumerator{N,S,C} <: AbstractSetNumber
    tag::TreeTag
    data::StaticElementVector{N,S,C}
    left::TreeConfigEnumerator{N,S,C}
    right::TreeConfigEnumerator{N,S,C}
    TreeConfigEnumerator(tag::TreeTag, left::TreeConfigEnumerator{N,S,C}, right::TreeConfigEnumerator{N,S,C}) where {N,S,C} = new{N,S,C}(tag, zero(StaticElementVector{N,S,C}), left, right)
    function TreeConfigEnumerator(data::StaticElementVector{N,S,C}) where {N,S,C}
        new{N,S,C}(LEAF, data)
    end
    function TreeConfigEnumerator{N,S,C}(tag::TreeTag) where {N,S,C}
        @assert  tag === ZERO
        return new{N,S,C}(tag)
    end
end

# AbstractTree APIs
function children(t::TreeConfigEnumerator)
    if t.tag == ZERO || t.tag == LEAF
        return typeof(t)[]
    else
        return [t.left, t.right]
    end
end
function printnode(io::IO, t::TreeConfigEnumerator)
    if t.tag === LEAF
        print(io, t.data)
    elseif t.tag === ZERO
        print(io, "∅")
    elseif t.tag === SUM
        print(io, "+")
    else  # PROD
        print(io, "*")
    end
end

Base.length(x::TreeConfigEnumerator) = _length(x, IdDict{typeof(x), Int}())

function _length(x, d)
    haskey(d, x) && return d[x]
    if x.tag === SUM
        l = _length(x.left, d) + _length(x.right, d)
        d[x] = l
        return l
    elseif x.tag === PROD
        l = _length(x.left, d) * _length(x.right, d)
        d[x] = l
        return l
    elseif x.tag === ZERO
        return 0
    else
        return 1
    end
end

num_nodes(x::TreeConfigEnumerator) = _num_nodes(x, IdDict{typeof(x), Int}())
function _num_nodes(x, d)
    haskey(d, x) && return 0
    if x.tag == ZERO
        res = 1
    elseif x.tag == LEAF
        res = 1
    else
        res = _num_nodes(x.left, d) + _num_nodes(x.right, d) + 1
    end
    d[x] = res
    return res
end

function Base.:(==)(x::TreeConfigEnumerator{N,S,C}, y::TreeConfigEnumerator{N,S,C}) where {N,S,C}
    return Set(collect(x)) == Set(collect(y))
end

Base.show(io::IO, t::TreeConfigEnumerator) = print_tree(io, t)

function Base.collect(x::TreeConfigEnumerator{N,S,C}) where {N,S,C}
    if x.tag == ZERO
        return StaticElementVector{N,S,C}[]
    elseif x.tag == LEAF
        return StaticElementVector{N,S,C}[x.data]
    elseif x.tag == SUM
        return vcat(collect(x.left), collect(x.right))
    else   # PROD
        return vec([reduce((x,y)->x|y, si) for si in Iterators.product(collect(x.left), collect(x.right))])
    end
end

function Base.:+(x::TreeConfigEnumerator{N,S,C}, y::TreeConfigEnumerator{N,S,C}) where {N,S,C}
    TreeConfigEnumerator(SUM, x, y)
end

function Base.:*(x::TreeConfigEnumerator{L,S,C}, y::TreeConfigEnumerator{L,S,C}) where {L,S,C}
    TreeConfigEnumerator(PROD, x, y)
end

Base.zero(::Type{TreeConfigEnumerator{N,S,C}}) where {N,S,C} = TreeConfigEnumerator{N,S,C}(ZERO)
Base.one(::Type{TreeConfigEnumerator{N,S,C}}) where {N,S,C} = TreeConfigEnumerator(zero(StaticElementVector{N,S,C}))
Base.zero(::TreeConfigEnumerator{N,S,C}) where {N,S,C} = zero(TreeConfigEnumerator{N,S,C})
Base.one(::TreeConfigEnumerator{N,S,C}) where {N,S,C} = one(TreeConfigEnumerator{N,S,C})
# todo, check siblings too?
function Base.iszero(t::TreeConfigEnumerator)
    if t.tag == SUM
        iszero(t.left) && iszero(t.right)
    elseif t.tag == ZERO
        true
    elseif t.tag == LEAF
        false
    else
        iszero(t.left) || iszero(t.right)
    end
end

# A patch to make `Polynomial{ConfigEnumerator}` work
function Base.:*(a::Int, y::AbstractSetNumber)
    a == 0 && return zero(y)
    a == 1 && return y
    error("multiplication between int and `$(typeof(y))` is not defined.")
end

# convert from counting type to bitstring type
for (F,TP) in [(:set_type, :ConfigEnumerator), (:sampler_type, :ConfigSampler), (:treeset_type, :TreeConfigEnumerator)]
    @eval begin
        function $F(::Type{T}, n::Int, nflavor::Int) where {OT, K, T<:TruncatedPoly{K,C,OT} where C}
            TruncatedPoly{K, $F(n,nflavor),OT}
        end
        function $F(::Type{T}, n::Int, nflavor::Int) where {TX, T<:Polynomial{C,TX} where C}
            Polynomial{$F(n,nflavor),:x}
        end
        function $F(::Type{T}, n::Int, nflavor::Int) where {TV, T<:CountingTropical{TV}}
            CountingTropical{TV, $F(n,nflavor)}
        end
        function $F(::Type{Real}, n::Int, nflavor::Int) where {TV}
            $F(n, nflavor)
        end
        function $F(n::Integer, nflavor::Integer)
            s = ceil(Int, log2(nflavor))
            c = _nints(n,s)
            return $TP{n,s,c}
        end
    end
end

# utilities for creating onehot vectors
onehotv(::Type{ConfigEnumerator{N,S,C}}, i::Integer, v) where {N,S,C} = ConfigEnumerator([onehotv(StaticElementVector{N,S,C}, i, v)])
onehotv(::Type{TreeConfigEnumerator{N,S,C}}, i::Integer, v) where {N,S,C} = TreeConfigEnumerator(onehotv(StaticElementVector{N,S,C}, i, v))
onehotv(::Type{ConfigSampler{N,S,C}}, i::Integer, v) where {N,S,C} = ConfigSampler(onehotv(StaticElementVector{N,S,C}, i, v))
# just to make matrix transpose work
Base.transpose(c::ConfigEnumerator) = c
Base.copy(c::ConfigEnumerator) = ConfigEnumerator(copy(c.data))
Base.transpose(c::TreeConfigEnumerator) = c
function Base.copy(c::TreeConfigEnumerator{N,S,C}) where {N,S,C}
    if c.tag == LEAF
        TreeConfigEnumerator(c.data)
    elseif c.tag == ZERO
        TreeConfigEnumerator{N,S,C}(c.tag)
    else
        TreeConfigEnumerator(c.tag, c.left, c.right)
    end
end

# Handle boolean, this is a patch for CUDA matmul
for TYPE in [:AbstractSetNumber, :TruncatedPoly, :ExtendedTropical]
    @eval Base.:*(a::Bool, y::$TYPE) = a ? y : zero(y)
    @eval Base.:*(y::$TYPE, a::Bool) = a ? y : zero(y)
end

# to handle power of polynomials
function Base.:^(x::TreeConfigEnumerator, y::Real)
    if y <= 0
        return one(x)
    elseif x.tag == LEAF
        return x
    else
        error("pow of non-leaf nodes is forbidden!")
    end
end
function Base.:^(x::ConfigEnumerator, y::Real)
    if y <= 0
        return one(x)
    elseif length(x) <= 1
        return x
    else
        error("pow of configuration enumerator of `size > 1` is forbidden!")
    end
end
function Base.:^(x::ConfigSampler, y::Real)
    if y <= 0
        return one(x)
    else
        return x
    end
end

# variable `x`
function _x(::Type{Polynomial{BS,X}}; invert) where {BS,X}
    @assert !invert   # not supported, because it is not useful
    Polynomial{BS,X}([zero(BS), one(BS)])
end
function _x(::Type{TruncatedPoly{K,BS,OS}}; invert) where {K,BS,OS}
    ret = TruncatedPoly{K,BS,OS}(ntuple(i->i<K ? zero(BS) : one(BS), K),one(OS))
    invert ? pre_invert_exponent(ret) : ret
end
function _x(::Type{CountingTropical{TV,BS}}; invert) where {TV,BS}
    ret = CountingTropical{TV,BS}(one(TV), one(BS))
    invert ? pre_invert_exponent(ret) : ret
end
function _x(::Type{Tropical{TV}}; invert) where {TV}
    ret = Tropical{TV}(one(TV))
    invert ? pre_invert_exponent(ret) : ret
end
function _x(::Type{ExtendedTropical{K,TO}}; invert) where {K,TO}
    ret =ExtendedTropical{K,TO}(map(i->i==K ? one(TO) : zero(Tropical{TO}).n, 1:K))
    invert ? pre_invert_exponent(ret) : ret
end

# for finding all solutions
function _x(::Type{T}; invert) where {T<:AbstractSetNumber}
    ret = one(T)
    invert ? pre_invert_exponent(ret) : ret
end

# negate the exponents before entering the solver
pre_invert_exponent(t::TruncatedPoly{K}) where K = TruncatedPoly(t.coeffs, -t.maxorder)
pre_invert_exponent(t::TropicalNumbers.TropicalTypes) = inv(t)
pre_invert_exponent(t::ExtendedTropical{K}) where K = ExtendedTropical{K}(map(i->i==K ? -t.orders[i] : t.orders[i], 1:K))
# negate the exponents after entering the solver
post_invert_exponent(t::TruncatedPoly{K}) where K = TruncatedPoly(ntuple(i->t.coeffs[K-i+1], K), -t.maxorder+(K-1))
post_invert_exponent(t::TropicalNumbers.TropicalTypes) = inv(t)
post_invert_exponent(t::ExtendedTropical{K}) where K = ExtendedTropical{K}(map(i->-t.orders[i], K:-1:1))