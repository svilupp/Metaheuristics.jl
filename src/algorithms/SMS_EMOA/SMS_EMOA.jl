include("front-contribution.jl")

mutable struct SMS_EMOA <: AbstractParameters
    N::Int
    η_cr::Float64
    p_cr::Float64
    η_m::Float64
    p_m::Float64
end

"""
    function SMS_EMOA(;
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

To use SMS_EMOA, the output from the objective function should be a 3-touple
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

# define the parameters (use `SMS_EMOA()` for using default parameters)
nsga2 = SMS_EMOA(N = 100, p_cr = 0.85)

# optimize
status = optimize(f, bounds, nsga2)

# show results
display(status)
```

"""
function SMS_EMOA(;
    N = 100,
    η_cr = 20,
    p_cr = 0.9,
    η_m = 20,
    p_m = -1,
    information = Information(),
    options = Options(),
)

    parameters = SMS_EMOA(N, promote( Float64(η_cr), p_cr, η_m, p_m)...)
    Algorithm(
        parameters,
        information = information,
        options = options,
    )

end



function update_state!(
    status::State,
    parameters::SMS_EMOA,
    problem::AbstractProblem,
    information::Information,
    options::Options,
    args...;
    kargs...
    )


    I = randperm(parameters.N)
    J = randperm(parameters.N)
    Q = typeof(status.population[1])[]
    for i = 1:2:parameters.N

        pa = tournament_selection(status.population, I[i])
        pb = tournament_selection(status.population, J[i])

        # crossover
        c1, c2 = SBX_crossover( get_position(pa), get_position(pb), problem.bounds,
                              parameters.η_cr, parameters.p_cr)
       
        # mutation
        polynomial_mutation!(c1,problem.bounds,parameters.η_m, parameters.p_m)
        polynomial_mutation!(c2,problem.bounds,parameters.η_m, parameters.p_m)
       
        # rapair solutions if necesary
        reset_to_violated_bounds!(c1, problem.bounds)
        reset_to_violated_bounds!(c2, problem.bounds)

        # evaluate children
        child1 = create_solution(c1, problem)

        child2 = create_solution(c2, problem) 
        status.f_calls += 2
       
        # save children
        push!(Q, child1)
        push!(Q, child2)
    end

    status.population = vcat(status.population, Q)

    # non-dominated sort, crowding distance, elitist removing
    compute_contribution!(status.population)

    stop_criteria!(status, parameters, problem, information, options)
end


function initialize!(
    status,
    parameters::SMS_EMOA,
    problem::AbstractProblem,
    information::Information,
    options::Options,
    args...;
    kargs...
)
    D = size(problem.bounds, 2)

    if parameters.p_m < 0.0
        parameters.p_m = 1.0 / D
    end

    if options.iterations == 0
        options.iterations = 500
    end

    if options.f_calls_limit == 0
        options.f_calls_limit = options.iterations * parameters.N + 1
    end

    status = gen_initial_state(problem,parameters,information,options,status)

    status

end

function final_stage!(
    status::State,
    parameters::SMS_EMOA,
    problem::AbstractProblem,
    information::Information,
    options::Options,
    args...;
    kargs...
    )
    status.final_time = time()

    #status.best_sol = get_pareto_front(status.population, is_better)

end

