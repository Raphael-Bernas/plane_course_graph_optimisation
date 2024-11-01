using Gurobi
using JuMP
using LinearAlgebra

# Include the readInstance function
include("lecture_distances.jl")

function solveInstanceDFJ(file::String)
    # Read instance data
    n, d, f, Amin, Nr, R, regions, coords, D = readInstance(file)
    
    # Create model for the main problem
    model = Model(Gurobi.Optimizer)
    
    # Decision variables
    @variable(model, x[1:n, 1:n], Bin)
    
    # Objective: Minimize total distance
    @objective(model, Min, sum(D[i,j] * x[i,j] for i in 1:n, j in 1:n))
    
    # Constraints
    # Departure and arrival constraints
    @constraint(model, sum(x[d,j] for j in 1:n) == 1)
    @constraint(model, sum(x[i,f] for i in 1:n) == 1)
    
    # Flow conservation constraints
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

    # Distance constraint
    for i in 1:n
        for j in 1:n 
            @constraint(model, x[i,j] * D[i,j] <= R) 
        end 
    end 

    # Function to solve the separation problem and find violated DFJ constraints
    function find_violated_dfj_constraint(x_sol)
        # Create a new model for the separation problem
        separation_model = Model(Gurobi.Optimizer)
        
        # Variables for separation problem
        @variable(separation_model, z[1:n], Bin)
        @variable(separation_model, w[1:n, 1:n] >= 0)
        
        # Objective function for the separation problem
        @objective(separation_model, Max, sum(w[i, j] * x_sol[i, j] for i in 1:n, j in 1:n) - sum(z[i] for i in 1:n) +1)
        
        # Constraints for w_ij variables
        for i in 1:n, j in 1:n
            @constraint(separation_model, w[i, j] <= z[i])
            @constraint(separation_model, w[i, j] <= z[j])
            @constraint(separation_model, w[i, j] >= z[i] + z[j] - 1)
            @constraint(separation_model, sum(z[i] for i in 1:n)>=1)
        end
        
        # Solve the separation model
        optimize!(separation_model)
        
        if termination_status(separation_model) == MOI.OPTIMAL
            # Check if the solution of the separation problem is > 0
            obj_value = objective_value(separation_model)
            if obj_value > 0
                # Retrieve violated subset S from z values
                violated_S = [i for i in 1:n if value(z[i]) > 0.5]
                return violated_S, obj_value
            end
        end
        return [], 0
    end

    # Main loop: solve, find violated DFJ constraints, and add them
    iteration = 0
    while true
        iteration += 1
        println("Iteration $iteration: Solving main problem")
        
        # Solve the main model
        optimize!(model)
        
        # Retrieve solution
        if termination_status(model) == MOI.OPTIMAL
            x_sol = value.(x)
            
            # Solve separation problem to find violated constraint
            violated_S, violation = find_violated_dfj_constraint(x_sol)
            
            # Check if no violation is found (stopping condition)
            if violation <= 0
                println("No violated DFJ constraints found. Optimal solution achieved.")
                break
            else
                println("Adding violated DFJ constraint for subset: $violated_S")
                
                # Add the violated DFJ constraint to the main model
                @constraint(model, sum(x[i, j] for i in violated_S, j in violated_S) <= length(violated_S) - 1)
            end
        else
            println("No feasible solution found.")
            break
        end
    end
    
    # Retrieve the optimal path if found
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

# Run the solver on a specific instance file
path = solveInstanceDFJ("./Instances/instance_6_1.txt")
println("Optimal path: ", path)

