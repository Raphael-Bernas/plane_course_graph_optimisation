using GraphRecipes
using Plots

const n = 15
const A = Float64[ rand() < 0.5 ? 0 : rand() for i=1:n, j=1:n]
for i=1:n
    A[i, 1:i-1] = A[1:i-1, i]
    A[i, i] = 0
end

edgelabel_dict = Dict()
for i=1:n
    for j=1:n
        if A[i, j] != 0
            edgelabel_dict[(i, j)] = string(A[i, j])
        end
    end
end

plt = graphplot(A,
          markersize = 0.2,
          node_weights = 1:n,
          markercolor = range(colorant"yellow", stop=colorant"red", length=n),
          names = 1:n,
          edgelabel=edgelabel_dict,
          fontsize = 10,
          linecolor = :darkgrey
          )

savefig(plt, "graph.png")  # Sauvegarde le graphique dans un fichier PNG

