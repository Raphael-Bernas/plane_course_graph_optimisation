using Gurobi
using JuMP
using LinearAlgebra

# Include the readInstance function
include("lecture_distances.jl")

function solveInstanceDFJ(file::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)
    
    # Create model
    model = Model(Gurobi.Optimizer)
    
    # Decision variables
    @variable(model, x[1:n, 1:n], Bin)
    
    # Objective: Minimize total distance
    @objective(model, Min, sum(D[i,j] * x[i,j] for i in 1:n, j in 1:n))
    
    # Constraints
    # Departure and arrival constraints
    @constraint(model, sum(x[d,j] for j in 1:n) == 1)
    @constraint(model, sum(x[i,f] for i in 1:n) == 1)
    
    for k in 1:n
        if k != d && k != f
            @constraint(model, sum(x[k,j] for j in 1:n) <= 1)
            @constraint(model, sum(x[i,k] for i in 1:n) == sum(x[k,j] for j in 1:n))
        end
    end
    
    # Minimum number of airports constraint
    @constraint(model, sum(x[i,j] for i in 1:n, j in 1:n) + 1 >= Amin)
    
    # Regional visit constraints
    for r in 1:Nr
        @constraint(model, sum(x[i,j]+x[j,i] for i in regions[r], j in 1:n) >= 1)
    end

    # R
    for i in 1:n
        for j in 1:n 
            @constraint(model, x[i,j]*D[i,j]<=R) 
        end 
    end 

    function find_subtours(sol)
        visited = fill(false, n)
        subtours = []
        
        for start in 1:n
            if !visited[start]
                tour = []
                current = start
                while !visited[current]
                    push!(tour, current)
                    visited[current] = true
                    for next in 1:n
                        if sol[current, next] > 0.5
                            current = next
                            break
                        end
                    end
                end
                push!(subtours, tour)
            end
        end
        return subtours
    end

    # Solve iteratively with DFJ constraints
    state = true
    while state
        optimize!(model)
        if termination_status(model) != MOI.OPTIMAL
            println("No optimal solution found.")
            return []
        end

        solution = value.(x)
        subtours = find_subtours(solution)
        
        if length(subtours) == 1
            state = false
        end

        for tour in subtours
            if length(tour) < n
                @constraint(model, sum(x[i,j] for i in tour, j in tour) <= length(tour) - 1)
            else
                state = false
            end
        end
    end
    
    path = []
    current = d
    while current != f
        for j in 1:n
            if solution[current, j] > 0.5
                push!(path, current)
                current = j
                break
            end
        end
    end
    push!(path, f)
    return path
end

current_path = pwd()
println("Current path: $current_path")
path = solveInstanceDFJ("Instances/instance_6_1.txt")
println("Optimal path: ", path)