using Graphs, OMEinsumContractionOrders
import StatsBase

"""
    random_square_lattice_graph(m::Int, n::Int, ρ::Real)

Create a random masked square lattice graph, with number of vertices fixed to ``\\lfloor mn\\rho \\rceil``.
"""
function random_square_lattice_graph(m::Int, n::Int, ρ::Real)
    @assert ρ >=0 && ρ <= 1
    square_lattice_graph(generate_mask(m, n, round(Int,m*n*ρ)))
end

"""
    square_lattice_graph(mask::AbstractMatrix{Bool})

Create a masked square lattice graph.
"""
function square_lattice_graph(mask::AbstractMatrix{Bool})
    locs = [(i, j) for i=1:size(mask, 1), j=1:size(mask, 2) if mask[i,j]]
    unit_disk_graph(locs, 1.1)
end

"""
    random_diagonal_coupled_graph(m::Int, n::Int, ρ::Real)

Create a ``m\\times n`` random masked diagonal coupled square lattice graph, 
with number of vertices equal to ``\\lfloor m \\times n\\times \\rho \\rceil``.
"""
function random_diagonal_coupled_graph(m::Int, n::Int, ρ::Real)
    @assert ρ >=0 && ρ <= 1
    diagonal_coupled_graph(generate_mask(m, n, round(Int,m*n*ρ)))
end
function generate_mask(Nx::Int, Ny::Int, natoms::Int)
    mask = zeros(Bool, Nx, Ny)
    mask[StatsBase.sample(1:Nx*Ny, natoms; replace=false)] .= true
    return mask
end

"""
    diagonal_coupled_graph(mask::AbstractMatrix{Bool})

Create a masked diagonal coupled square lattice graph from a specified `mask`.
"""
function diagonal_coupled_graph(mask::AbstractMatrix{Bool})
    locs = [(i, j) for i=1:size(mask, 1), j=1:size(mask, 2) if mask[i,j]]
    unit_disk_graph(locs, 1.5)
end

"""
    unit_disk_graph(locs::AbstractVector, unit::Real)

Create a unit disk graph with locations specified by `locs` and unit distance `unit`.
"""
function unit_disk_graph(locs::AbstractVector, unit::Real)
    n = length(locs)
    g = SimpleGraph(n)
    for i=1:n, j=i+1:n
        if sum(abs2, locs[i] .- locs[j]) < unit ^ 2
            add_edge!(g, i, j)
        end
    end
    return g
end

"""
    line_graph(g::SimpleGraph)

Returns the line graph of `g`.
The line graph is generated by mapping an edge to a vertex and two edges sharing a common vertex will be connected.
"""
function line_graph(graph::SimpleGraph)
    edge_list = collect(edges(graph))
    linegraph = SimpleGraph(length(edge_list))
    for (i, ei) in enumerate(edge_list)
        for (j, ej) in enumerate(edge_list)
            if ei.src ∈ (ej.src, ej.dst) || ei.dst ∈ (ej.src, ej.dst)
                add_edge!(linegraph, i, j)
            end
        end
    end
    return linegraph
end
