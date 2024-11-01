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
    if i > k 
        if visited[path[k]] == 1
            return visited, 0
        else
            return visited, visited[path[i-1]]
        end
    end
    return visited, visited[path[i]]
end

function test_subtour(n, d, solution)
    visited=zeros(Int,n)
    visited[d] = 1
    i = 1
    no_loop = true
    while i <= n && no_loop
        for j in 1:n
            visited[j] += solution[i,j]
            if visited[j] > 1
                no_loop = false
                break
            end
        end
        i += 1
    end
    if no_loop
        return visited, 0
    end
    return visited, 1
end