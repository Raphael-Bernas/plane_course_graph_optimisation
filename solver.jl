using Gurobi
using JuMP
using LinearAlgebra

# Include the readInstance function
include("lecture_distances.jl")

function solveInstance(file::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)
    
    # Create model
    model = Model(Gurobi.Optimizer)
    
    # Decision variables
    @variable(model, x[1:n, 1:n], Bin)
    @variable(model, u[1:n], Int)
    
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
    
    # MTZ constraints for subtour elimination
    for i in 2:n
        for j in 2:n
            if i != j
                @constraint(model, u[j] >= u[i] + 1 - n * (1 - x[i,j]))
            end
        end
    end
    
    # Regional visit constraints
    for r in 1:Nr
        @constraint(model, sum(x[i,j] for i in regions[r], j in 1:n) >= 1)
    end
    
    # Solve the model
    optimize!(model)
    
    # Retrieve the results
    if termination_status(model) == MOI.OPTIMAL
        solution = value.(x)
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
    else
        println("No optimal solution found.")
        return []
    end
end

path = solveInstance("/home/bernas/VSC/JULIA/SOD321/project/Instances/instance_6_1.txt")
println("Optimal path: ", path)