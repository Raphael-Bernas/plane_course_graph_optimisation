using JuMP
using Gurobi
include("lecture_distances.jl")

n,d,f,Amin,Nr,R,regions,coords,D=readInstance("instance_6_1.txt")    # n,d,f,Amin,Nr,R,regions,coords,D

# Modèle
model = Model(Gurobi.Optimizer)

# Calcul des distances euclidiennes
dist=zeros(Int,n,n)
for i in 1:n
    for j in 1:n 
        dist[i,j]=floor(sqrt((coords[i,1]-coords[j,1])^2+(coords[i,2]-coords[j,2])^2))
    end
end

# Variables de décision
@variable(model, x[1:n,1:n]>=0, Bin)  # Variables x_ij
@variable(model, u[1:n]>=0, Int)  # Variables x_ij

# Fonction objectif à minimiser
@objective(model, Min, sum(sum(x[i,j]*dist[i,j] for j in 1:n) for i in 1:n))

# Contraintes
@constraint(model,sum(x[d,j] for j in 1:n)==1) # on part de d
@constraint(model,sum(x[i,f] for i in 1:n)==1) # on arrive en f
for k in 1:n
    if k!=d && k!=f
        @constraint(model, sum(x[i, k] for i in 1:n)<=1)
    end
end 
for k in 1:n
    if k!=d && k!=f
        @constraint(model, sum(x[k,j] for j in 1:n)==sum(x[i,k] for i in 1:n))
    end
end 
@constraint(model, sum(sum(x[i,j] for j in 1:n) for i in 1:n)+1>=Amin)  # contrainte Amin
for i in 1:n
    for j in 1:n 
        @constraint(model, x[i,j]*dist[i,j]<=R) 
    end 
end 
@constraint(model, [i in 1:n, j in 1:n], u[j]>=u[i]+1-n*(1-x[i,j])) # connexité MTZ
for r in 1:Nr
    @constraint(model,sum(x[i,j]+x[j,i] for i in regions[r], j in 1:n)>=1)
end
    
# Résoudre le modèle
optimize!(model)

# Affichage des résultats
if termination_status(model) == MOI.OPTIMAL
    println("Solution optimale trouvée:")
    println("x:", value.(x))
    println("u:", value.(u))
    println("Coût total:", objective_value(model))
else
    println("Aucune solution optimale trouvée.")
end


