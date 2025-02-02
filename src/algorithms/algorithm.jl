"""
    gen_initial_state(problem,parameters,information,options)

Generate an initial state, i.e., compute uniformly distributed random vectors in bounds,
after that are evaluated in objective function. This method require that `parameters.N`
is valid attribute.
"""
gen_initial_state(problem,parameters,information,options,status::State{Any}) = gen_initial_state(problem,parameters,information,options)


function gen_initial_state(problem,parameters,information,options, status)
    parameters.N != length(status.population) &&
        error("Population size in provided State differs from that in parameters")


    size(problem.bounds,2) != length(get_position(status.best_sol)) &&
        error("Invalid population (dimension does not match with bounds)")

    return State(status.best_sol, status.population)

    
end

function gen_initial_state(problem,parameters,information,options)
    # population array
    population = generate_population(parameters.N, problem,ε=options.h_tol)

    # best solution
    best_solution = get_best(population)

    return State(best_solution, population; f_calls = length(population), iteration=1)
end

function Base.show(io::IO, parameters::AbstractParameters)
    s = typeof(parameters)

    vals = string.(map(f -> getfield(parameters, f), fieldnames(s)))
    str = string(s) * "(" * join(string.(fieldnames(s)) .* "=" .* vals, ", ") * ")"

    print(io, str)
end

