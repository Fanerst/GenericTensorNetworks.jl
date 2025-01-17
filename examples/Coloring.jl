# # Coloring problem

# !!! note
#     It is highly recommended to read the [Independent set problem](@ref) chapter before reading this one.

# ## Problem definition
# A [vertex coloring](https://en.wikipedia.org/wiki/Graph_coloring) is an assignment of labels or colors to each vertex of a graph such that no edge connects two identically colored vertices. 
# In the following, we are going to defined a 3-coloring problem for the Petersen graph.

using GenericTensorNetworks, Graphs

graph = Graphs.smallgraph(:petersen)

# We can visualize this graph using the following function
rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a

locations = [[rot15(0.0, 1.0, i) for i=0:4]..., [rot15(0.0, 0.6, i) for i=0:4]...]

show_graph(graph; locs=locations)

# ## Generic tensor network representation
#
# We construct the tensor network for the 3-coloring problem as
problem = Coloring{3}(graph);

# ### Theory (can skip)
# Type [`Coloring`](@ref) can be used for constructing the tensor network with optimized contraction order for a coloring problem.
# Let us use 3-coloring problem defined on vertices as an example.
# For a vertex ``v``, we define the degree of freedoms ``c_v\in\{1,2,3\}`` and a vertex tensor labelled by it as
# ```math
# W(v) = \left(\begin{matrix}
#     1\\
#     1\\
#     1
# \end{matrix}\right).
# ```
# For an edge ``(u, v)``, we define an edge tensor as a matrix labelled by ``(c_u, c_v)`` to specify the constraint
# ```math
# B = \left(\begin{matrix}
#     1 & x & x\\
#     x & 1 & x\\
#     x & x & 1
# \end{matrix}\right).
# ```
# The number of possible coloring can be obtained by contracting this tensor network by setting vertex tensor elements ``r_v, g_v`` and ``b_v`` to 1.

# ## Solving properties
# ##### counting all possible coloring
num_of_coloring = solve(problem, CountingMax())[]

# ##### finding one best coloring
single_solution = solve(problem, SingleConfigMax())[]

is_vertex_coloring(graph, single_solution.c.data)

vertex_color_map = Dict(0=>"red", 1=>"green", 2=>"blue")

show_graph(graph; locs=locations, vertex_colors=[vertex_color_map[Int(c)]
     for c in single_solution.c.data])

# Let us try to solve the same issue on its line graph, a graph that generated by mapping an edge to a vertex and two edges sharing a common vertex will be connected.
linegraph = line_graph(graph)

show_graph(linegraph; locs=[0.5 .* (locations[e.src] .+ locations[e.dst])
     for e in edges(graph)])

# Let us construct the tensor network and see if there are solutions.
lineproblem = Coloring{3}(linegraph);

num_of_coloring = solve(lineproblem, CountingMax())[]

# You will see the maximum size 28 is smaller than the number of edges in the `linegraph`,
# meaning no solution for the 3-coloring on edges of a Petersen graph.
