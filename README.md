# GenericTensorNetworks

[![Build Status](https://github.com/QuEraComputing/GenericTensorNetworks.jl/workflows/CI/badge.svg)](https://github.com/QuEraComputing/GenericTensorNetworks.jl/actions)
[![codecov](https://codecov.io/gh/QuEraComputing/GenericTensorNetworks.jl/branch/master/graph/badge.svg?token=vwWQntOxvG)](https://codecov.io/gh/QuEraComputing/GenericTensorNetworks.jl)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/)


This package implements generic tensor networks to compute *solution space properties* of a class of hard combinatorial problems.
The *solution space properties* include
* The maximum/minimum solution sizes,
* The number of solutions at certain sizes,
* The enumeration of solutions at certain sizes.
* The direct sampling of solutions at certain sizes.

The solvable problems include [Independent set problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/IndependentSet/), [Maximal independent set problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/MaximalIS/), [Cutting problem (Spin-glass problem)](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/MaxCut/), [Vertex matching problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/Matching/), [Binary paint shop problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/PaintShop/), [Coloring problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/Coloring/), [Dominating set problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/DominatingSet/), [Set packing problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/SetPacking/), [Satisfiability problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/Satisfiability/) and [Set covering problem](https://queracomputing.github.io/GenericTensorNetworks.jl/dev/tutorials/SetCovering/).

## Installation
<p>
GenericTensorNetworks is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install GenericTensorNetworks,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type
</p>

```julia
pkg> add GenericTensorNetworks
```

To update, just type `up` in the package mode.

We recommend using **Julia version >= 1.7**, otherwise your program can suffer from significant (exponential in tensor dimension) overheads when permuting the dimensions of a large tensor.
If you have to use an older version Julia, you can overwrite the `LinearAlgebra.permutedims!` by adding the following patch to your own project.

```julia
# only required when your Julia version < 1.7
using TensorOperations, LinearAlgebra
function LinearAlgebra.permutedims!(C::Array{T,N}, A::StridedArray{T,N}, perm) where {T,N}
    if isbitstype(T)
        TensorOperations.tensorcopy!(A, ntuple(identity,N), C, perm)
    else
        invoke(permutedims!, Tuple{Any,AbstractArray,Any}, C, A, perm)
    end
end
```

## Supporting and Citing

Much of the software in this ecosystem was developed as part of academic research.
If you would like to help support it, please star the repository as such metrics may help us secure funding in the future.
If you use our software as part of your research, teaching, or other activities, we would be grateful if you could cite our work.
The
[CITATION.bib](https://github.com/QuEraComputing/GenericTensorNetworks.jl/blob/master/CITATION.bib) file in the root of this repository lists the relevant papers.

## Questions and Contributions

You can
* Post a question on [Julia Discourse forum](https://discourse.julialang.org/), pin the package maintainer wih `@1115`.
* Discuss in the `#graphs` channel of the [Julia Slack](https://julialang.org/community/), ping the package maintainer with `@JinGuo Liu`.
* Open an [issue](https://github.com/QuEraComputing/GenericTensorNetworks.jl/issues) if you encounter any problems, or have any feature request.
