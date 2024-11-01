using Gurobi
using JuMP
using LinearAlgebra

# Include the readInstance function
include("lecture_distances.jl")
include("subtour.jl")

function solveInstanceMTZ(file::String)
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
    for i in 1:n
        for j in 1:n
            @constraint(model, u[j] >= u[i] + 1 - n * (1 - x[i,j]))
        end
    end
    
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
    
    # DFJ constraints for subtour elimination
    for S in 1:(2^n - 1)
        subset = [i for i in 1:n if (S >> (i-1)) & 1 == 1]
        if 1 <= length(subset) <= n - 1
            @constraint(model, sum(x[i,j] for i in subset, j in subset) <= length(subset) - 1)
        end
    end
    
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
        visited, n_subtours = test_subtour(n, d, solution)
        println("Visited: ", visited)
        push!(path, f)
        return path
    else
        println("No optimal solution found.")
        return []
    end
end

function solveInstanceSubDFJ(file::String)
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
    @constraint(model, sum(x[f,i] for i in 1:n) == 0)
    @constraint(model, sum(x[i,d] for i in 1:n) == 0)
    
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

    # blocking self-loops
    for i in 1:n
        @constraint(model, x[i,i] <= 0)
    end
    @constraint(model, x[d,f] <= 0)

    # R
    for i in 1:n
        for j in 1:n 
            @constraint(model, x[i,j]*D[i,j]<=R) 
        end 
    end
    n_constraints = 0
    n_subtours = 1
    path = []
    visited = zeros(Int, n)
    while n_subtours > 0 && n_constraints < 2^n
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
        else
            println("No optimal solution found.")
            path = []
        end
        visited, n_subtours = test_subtour(n, d, solution)
        subset = [i for i in 1:n if visited[i] > 0 ]
        # println("Visited: ", visited)
        # println("Path: ", path)
        new_subset = []
        if n_subtours == 0
            for state in subset
                if !in(state, path)
                    new_subset = push!(new_subset, state)
                end
            end
        end
        if length(new_subset) > 0
            n_subtours = 1
            subset = new_subset
        end
        if n_subtours > 0
            n_constraints += 1
            println("Number of current DFJ constraints: ", n_constraints)
            println("Adding constraint: ")
            println(subset)
            @constraint(model, sum(x[i,j] for i in subset, j in subset) <= length(subset) - 1)
        end
    end
    return path, n_constraints, visited
end

results = @timed begin
path = solveInstanceDFJ("./Instances/instance_20_1.txt")
println("Optimal path: ", path)

# path, n_constraints, visited = solveInstanceSubDFJ("./Instances/instance_6_2.txt")
# println("Optimal path: ", path)
# println("Final visited: ", visited)
# println("Number of constraints added: ", n_constraints)

# path = solveInstanceMTZ("./Instances/instance_20_1.txt")
# println("Optimal path: ", path)
end

println("Elapsed time: ", results.time, " seconds")
