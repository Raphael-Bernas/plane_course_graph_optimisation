using GraphRecipes
using Plots

# Include the solver function and the readInstance function
include("solver.jl")
include("lecture_distances.jl")

function animateGraphTraversal(file::String, output_path::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)
    
    # Solve the instance to get the optimal path
    path = solveInstanceMTZ(file)  # or solveInstanceDFJ(file) depending on your choice
    
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
    
    # Prepare the animation
    anim = @animate for step in 1:length(path)
        node_colors = fill(:yellow, n)
        for k in 1:step
            node_colors[path[k]] = :red
        end
        
        graphplot(A,
                  markersize = 0.2,
                  node_weights = 1:n,
                  markercolor = node_colors,
                  names = 1:n,
                  edgelabel=edgelabel_dict,
                  fontsize = 10,
                  linecolor = :darkgrey
                  )
    end
    
    # Save the animation to the specified output path
    gif(anim, output_path, fps = 1)
end

animateGraphTraversal("/home/bernas/VSC/JULIA/SOD321/project/Instances/instance_6_1.txt", "graph_traversal.gif")