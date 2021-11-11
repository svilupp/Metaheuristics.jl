# Abstracts for algorithm parameters
mutable struct SPEA2 <: AbstractNSGA
    N::Int
    η_cr::Float64
    p_cr::Float64
    η_m::Float64
    p_m::Float64
    fitness::Vector{Float64}
end

"""
    SPEA2(;
        N = 100,
        η_cr = 20,
        p_cr = 0.9,
        η_m = 20,
        p_m = 1.0 / D,
        information = Information(),
        options = Options(),
    )

Parameters for the metaheuristic NSGA-II.

Parameters:

- `N` Population size.
- `η_cr`  η for the crossover.
- `p_cr` Crossover probability.
- `η_m`  η for the mutation operator.
- `p_m` Mutation probability (1/D for D-dimensional problem by default).

To use SPEA2, the output from the objective function should be a 3-touple
`(f::Vector, g::Vector, h::Vector)`, where `f` contains the objective functions,
`g` and `h` are inequality, equality constraints respectively.

A feasible solution is such that `g_i(x) ≤ 0 and h_j(x) = 0`.


```julia
using Metaheuristics

# Dimension
D = 2

# Objective function
f(x) = ( x, [sum(x.^2) - 1], [0.0] ) 

# bounds
bounds = [-1 -1;
           1  1.0
        ]

# define the parameters (use `SPEA2()` for using default parameters)
nsga2 = SPEA2(N = 100, p_cr = 0.85)

# optimize
status = optimize(f, bounds, nsga2)

# show results
display(status)
```

"""
function SPEA2(;
    N = 100,
    η_cr = 20,
    p_cr = 0.9,
    η_m = 20,
    p_m = -1,
    information = Information(),
    options = Options(),
)

    parameters = SPEA2(N, promote( Float64(η_cr), p_cr, η_m, p_m )...,[])
    Algorithm(
        parameters,
        information = information,
        options = options,
    )

end



function update_state!(
    status::State,
    parameters::SPEA2,
    problem::AbstractProblem,
    information::Information,
    options::Options,
    args...;
    kargs...
    )
    if isempty(parameters.fitness)
        parameters.fitness = compute_fitness(status.population)
    end

    Q = empty(status.population)
    for i = 1:2:parameters.N

        pa = binary_tournament(status.population, parameters.fitness)
        pb = binary_tournament(status.population, parameters.fitness)

        offspring1, offspring2 = reproduction(pa, pb, parameters, problem)
       
        # save offsprings
        push!(Q, offspring1, offspring2)
    end

    status.population = vcat(status.population, Q)

    # non-dominated sort, crowding distance, elitist removing
    environmental_selection!(status.population, parameters)

end



function environmental_selection!(population, parameters::SPEA2)
    fitness = compute_fitness(population)
    N = parameters.N

    next = fitness .< 1
    if sum(next) < N
        rank = sortperm(fitness)
        next[rank[1:N]] .= true
    elseif sum(next) > N
        del  = truncation(population[next],sum(next)-N)
        temp = findall(next)
        next[temp[del]] .= false
    end

    deleteat!(population, .!next)
    deleteat!(fitness, .!next)
    parameters.fitness = fitness

end

function compute_distances(population)    
    N = length(population)

    distances = zeros(N,N)
    for i in 1:N
        distances[i,i] = Inf
        for j in i+1:N
            distances[i,j] = norm(fval(population[i]) - fval(population[j]))
            distances[j,i] = distances[i,j]
        end
    end

    return distances 
end

function truncation(population,K)
    #% Select part of the solutions by truncation
    Distance = compute_distances(population)
    Del = zeros(Bool, length(population))
    while sum(Del) < K
        Remain   = findall(.!Del)
        Temp     = sort(Distance[Remain,Remain], dims = 2)
        Rank     = sortslicesperm(Temp, dims=1)
        Del[Remain[Rank[1]]] = true
    end

    return Del
end

function compute_fitness(population)
    N = length(population)
    dominate = zeros(Bool,N, N)
    for i in 1:N-1
        for j in i+1 : N
            # k = any(PopObj(i,:)<PopObj(j,:)) - any(PopObj(i,:)>PopObj(j,:))
            k = compare(population[i], population[j])
            if k == 1
                dominate[i,j] = true
            elseif k == 2
                dominate[j,i] = true
            end
        end
    end

    S = sum(dominate,dims=2)[:,1]
    R = [ sum(S[dominate[:,i]]) for i in 1:N]

    distance = sort(compute_distances(population),dims=2)


    D = 1 ./ (distance[:,floor(Int,sqrt(N))] .+ 2)
    return R + D
end

