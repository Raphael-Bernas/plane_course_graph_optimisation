using Gurobi
using JuMP
using LinearAlgebra

# Include the readInstance function
include("lecture_distances.jl")
include("subtour.jl")

function solveInstanceFlowModel(file::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)

    # Create model
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "Presolve", 0)


    # Decision variables
    @variable(model, x[1:n, 1:n], Bin)  # Binary variables for tour inclusion
    @variable(model, flow[1:n, 1:n] >= 0)  # Flow variables to enforce connectivity

    # Objective: Minimize total distance
    @objective(model, Min, sum(D[i, j] * x[i, j] for i in 1:n, j in 1:n))

    # Constraints
    # Departure and arrival constraints
    @constraint(model, sum(x[d, j] for j in 1:n) == 1)
    @constraint(model, sum(x[i, f] for i in 1:n) == 1)

    # Degree constraints for each node
    for k in 1:n
        if k != d && k != f
            @constraint(model, sum(x[k, j] for j in 1:n) <= 1)
            @constraint(model, sum(x[i, k] for i in 1:n) == sum(x[k, j] for j in 1:n))
        end
    end

    # Minimum number of airports constraint
    @constraint(model, sum(x[i, j] for i in 1:n, j in 1:n) + 1 >= Amin)

    # Flow-based subtour elimination constraints
    # Starting node flow constraint
    for j in 2:n
        @constraint(model, flow[d, j] == x[d, j])
    end

    # Flow conservation for nodes (ensures that no subtour forms)
    for i in 2:n
        for j in 2:n
            if i != j
                @constraint(model, flow[i, j] <= (n - 1) * x[i, j])
            end
        end
    end

    # Flow balance constraint (ensures continuity)
    for i in 2:n
        @constraint(model, sum(flow[j, i] for j in 1:n if j != i) - sum(flow[i, j] for j in 1:n if j != i) == x[d, i] - x[i, f])
    end

    # Regional visit constraints
    for r in 1:Nr
        @constraint(model, sum(x[i, j] + x[j, i] for i in regions[r], j in 1:n) >= 1)
    end

    # Distance constraint for maximum range R
    for i in 1:n
        for j in 1:n
            @constraint(model, x[i, j] * D[i, j] <= R)
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

results = @timed begin
    path = solveInstanceFlowModel("./Instances/instance_10_1.txt")
    println("Optimal path: ", path)
    end
    
println("Elapsed time: ", results.time, " seconds")