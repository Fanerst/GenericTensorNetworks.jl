# # Cutting problem (Spin-glass problem)

# !!! note
#     It is highly recommended to read the [Independent set problem](@ref) chapter before reading this one.

# ## Problem definition
# In graph theory, a [cut](https://en.wikipedia.org/wiki/Cut_(graph_theory)) is a partition of the vertices of a graph into two disjoint subsets.
# It is closely related to the [spin-glass](https://en.wikipedia.org/wiki/Spin_glass) problem in physics.
# Finding the maximum cut is NP-Hard, where a maximum cut is a cut whose size is at least the size of any other cut,
# where the size of a cut is the number of edges (or the sum of weights on edges) crossing the cut.

using GenericTensorNetworks, Graphs

# In the following, we are going to defined an cutting problem for the Petersen graph.

graph = Graphs.smallgraph(:petersen)

# We can visualize this graph using the following function
rot15(a, b, i::Int) = cos(2i*π/5)*a + sin(2i*π/5)*b, cos(2i*π/5)*b - sin(2i*π/5)*a

locations = [[rot15(0.0, 1.0, i) for i=0:4]..., [rot15(0.0, 0.6, i) for i=0:4]...]

show_graph(graph; locs=locations)

# ## Generic tensor network representation
# We define the cutting problem as
problem = MaxCut(graph);

# ### Theory (can skip)
#
# For a vertex ``v\in V``, we define a boolean degree of freedom ``s_v\in\{0, 1\}``.
# Then the maximum cutting problem can be encoded to tensor networks by mapping an edge ``(i,j)\in E`` to an edge matrix labelled by ``s_is_j``
# ```math
# B(x_{\langle i, j\rangle}) = \left(\begin{matrix}
#     1 & x_{\langle i, j\rangle}^{w_{\langle i,j \rangle}}\\
#     x_{\langle i, j\rangle}^{w_{\langle i,j \rangle}} & 1
# \end{matrix}\right),
# ```
# If and only if there is a cut on edge ``(i, j)``,
# this tensor contributes a factor ``x_{\langle i, j\rangle}^{w_{\langle i,j \rangle}}``,
# where ``w_{\langle i,j\rangle}`` is the weight of this edge.
# Similar to other problems, we can define a polynomial about edges variables by setting ``x_{\langle i, j\rangle} = x``,
# where its k-th coefficient is two times the number of configurations of cut size k.

# Its contraction time space complexity is ``2^{{\rm tw}(G)}``, where ``{\rm tw(G)}`` is the [tree-width](https://en.wikipedia.org/wiki/Treewidth) of ``G``.

# ## Solving properties
# ### Maximum cut size ``\gamma(G)``
max_cut_size = solve(problem, SizeMax())[]

# ### Counting properties
# ##### graph polynomial
# The graph polynomial defined for the cutting problem is
# ```math
# C(G, x) = \sum_{k=0}^{\gamma(G)} c_k x^k,
# ```
# where ``\alpha(G)`` is the maximum independent set size, 
# ``c_k/2`` is the number of cuts of size ``k`` in graph ``G=(V,E)``.
# Since the variable ``x`` is defined on edges,
# the coefficients of the polynomial is the number of configurations having different number of anti-parallel edges.
max_config = solve(problem, GraphPolynomial())[]

# ### Configuration properties
# ##### finding one max cut solution
max_vertex_config = solve(problem, SingleConfigMax())[].c.data

max_cut_size_verify = cut_size(graph, max_vertex_config)

# You should see a consistent result as above `max_cut_size`.

show_graph(graph; locs=locations, vertex_colors=[
        iszero(max_vertex_config[i]) ? "white" : "red" for i=1:nv(graph)])

# where red vertices and white vertices are separated by the cut.
