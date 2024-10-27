function find_length_subtour(n,path)
    visited=zeros(Int,n)
    k = length(path)
    i = 1
    while i <= k && visited[path[i]] == 0
        for j in 1:i
            visited[path[j]] += 1
        end
        i += 1
    end
    return visited, visited[path[i]]
end