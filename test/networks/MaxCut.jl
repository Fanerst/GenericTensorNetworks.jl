using GenericTensorNetworks, Test, Graphs
using GenericTensorNetworks: max_size

@testset "graph utils" begin
    g2 = SimpleGraph(3)
    add_edge!(g2, 1,2)
    for g in [smallgraph(:petersen), g2]
        gp = MaxCut(g)
        mc = max_size(gp)
        config = solve(gp, SingleConfigMax())[].c.data
        @test cut_size(g, config) == mc
    end
    g = smallgraph(:petersen)
    # weighted
    weights = collect(1:ne(g))
    gp = MaxCut(g; weights=weights)
    mc = max_size(gp)
    config = solve(gp, SingleConfigMax())[].c.data
    @test solve(gp, CountingMax())[].c == 2
    @test cut_size(g, config; weights=weights) == mc
end

@testset "spinglass" begin
    g = SimpleGraph(5)
    for (i,j) in [(1,2),(2,3),(3,4),(4,1),(1,5),(2,4)]
        add_edge!(g, i, j)
    end
    @test graph_polynomial(MaxCut(g), Val(:polynomial))[] == Polynomial([2,2,4,12,10,2])
    @test graph_polynomial(MaxCut(g), Val(:finitefield))[] == Polynomial([2,2,4,12,10,2])
end

@testset "enumerating - max cut" begin
    g = SimpleGraph(5)
    for (i,j) in [(1,2),(2,3),(3,4),(4,1),(1,5),(2,4)]
        add_edge!(g, i, j)
    end
    code = MaxCut(g; optimizer=GreedyMethod())
    res = best_solutions(code; all=true)[]
    @test length(res.c.data) == 2
    @test cut_size(g, res.c.data[1]) == 5
end

@testset "fix vertices - max vut" begin
    g = SimpleGraph(5)
    for (i,j) in [(1,2),(2,3),(3,4),(4,1),(1,5),(2,4)]
        add_edge!(g, i, j)
    end
    fixedvertices = Dict(1=>1, 4=>0)
    problem = MaxCut(g, fixedvertices=fixedvertices)
    optimal_config = solve(problem, ConfigsMax())[].c
    @test length(optimal_config) == 1
    @test optimal_config[1] == StaticBitVector(Array{Bool, 1}([1, 0, 1, 0, 0]))
end
