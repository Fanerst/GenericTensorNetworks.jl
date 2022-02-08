using GraphTensorNetworks, Test, Graphs

@testset "visualize" begin
    locations = [(1.0, 2.0), (2.0, 3.0)]
    @test show_graph(locations, [(1, 2)]) isa Any
    @test show_graph(smallgraph(:petersen); locs=[(randn(), randn()) for i=1:10]) isa Any
end