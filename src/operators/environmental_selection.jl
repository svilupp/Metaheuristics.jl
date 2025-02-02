"""
    GenerationalReplacement()

Generational replacement.
"""
struct GenerationalReplacement end

function environmental_selection!(population, offsprings, parameters::GenerationalReplacement)
    @assert length(population) == length(offsprings)
    population[:] = offsprings
end

"""
    ElitistReplacement()

Offspring is inserted in population to keep the best individuals (keep population size).
"""
struct ElitistReplacement end

function environmental_selection!(
        population,
        offsprings,
        parameters::ElitistReplacement;
        is_better = is_better
    )

    N = length(population)
    append!(population, offsprings)
    sort!(population, lt=is_better)
    deleteat!(population, N+1:length(population))
end
