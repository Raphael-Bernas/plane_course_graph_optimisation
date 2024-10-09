using GraphRecipes
using Plots

# Include the readInstance function
include("lecture_distances.jl")

function plotGraph(file::String, output_path::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)
    
    # Create adjacency matrix A based on distance matrix D
    A = Float64[ if D[i, j] <= R D[i, j] else 0 end for i=1:n, j=1:n ]
    
    # Ensure the matrix is symmetric and no self-loops
    for i in 1:n
        A[i, 1:i-1] = A[1:i-1, i]
        A[i, i] = 0
    end
    
    # Create edge labels dictionary
    edgelabel_dict = Dict{Tuple{Int, Int}, String}()
    for i in 1:n
        for j in 1:n
            if A[i, j] != 0
                edgelabel_dict[(i, j)] = string(A[i, j])
            end
        end
    end

    # Plot the graph
    plt = graphplot(A,
              markersize = 0.2,
              node_weights = 1:n,
              markercolor = range(colorant"yellow", stop=colorant"red", length=n),
              names = 1:n,
              edgelabel=edgelabel_dict,
              fontsize = 10,
              linecolor = :darkgrey
              )
    
    # Save the graph to the specified output path
    savefig(plt, output_path)
end

plotGraph("/home/bernas/VSC/JULIA/SOD321/project/Instances/instance_6_1.txt", "graphique.png")