# plane_course_graph_optimisation

Ce répertoire contient les codes nécessaire a la résolution d'une variante du problème du voyageur du commerce : la course d'avion.

## Fichier principaux :

**solver.jl** : Il s'agit du fichier principal qui contient les méthodes MTZ, DFJ et OptiDFJ (une autre méthode, SubDFJ y est implémanté mais elle ne permet pas de résoudre un problème exactement équivalent au notre)

**solver_sep.jl** : Il s'agit d'une variante du solver pour la méthode DFJ utilisant le problème de séparation comme intermédiaire.

**solver_flow.jl** : Il s'agit d'une variante du solver pour la méthode MTZ.

## Fichier secondaire :

**lecture_distance.jl** : fichier intermédiaire permettant de lire les instances.

**subtour.jl** : fichier intermédiaire implémantant différent algorithme nécessaire a la détection de sous-tour ou a leurs études.

**graph_animation.jl** : génère une vidéo de la traversé d'un avion pour une instance donnée.

**graph_generation.jl** : génère un graphe fixe d'un problème pour une instance donnée.
