struct Filter{T} 
    fn :: Function
    desc :: String
end

function TrivialFilter(::Type{T}) where T
    return Filter{T}((x...) -> true, "")
end

function NotFilter(filter :: Filter{T}) where T
    Fn(x...) = !filter.fn(x...)
    newDesc = "$(@red("Not")) " * filter.desc
    return Filter{T}(Fn, newDesc)
end

function OrFilter(filterList :: Vector{Filter{T}}) where T
    Fn(x...) = any([filter.fn(x...) for filter in filterList])

    io = IOBuffer()
    println(io, "$(@red("Or")) Filter with $(length(filterList)) condition$(length(filterList) > 1 ? "s" : ""):")
    for (idx, filter) in enumerate(filterList)
        println(io, "- $(@dim(string(idx))): " * filter.desc)
    end
    newDesc = String(take!(io))

    return Filter{T}(Fn, newDesc)
end

function EvalFilter(::Type{T}, str) where T
    Entries = split(str, ":")
    Fn(x...) = (FilterRegistry[Entries[1]])(x..., Entries[2:end]...)
    newDesc = "Custom Filter: $(@blue(str))"

    return Filter{T}(Fn, newDesc)
end

function constructGeneralFilter(::Type{T}, input) where T
    parts = split(input, "|")
    if length(parts) > 1
        return OrFilter([constructGeneralFilter(T, x) for x in parts])
    end

    Ct = 0
    while Ct < length(input) && input[Ct+1] == '^'
        Ct += 1
    end
    if Ct > 0
        if Ct % 2 == 1
            return NotFilter(constructGeneralFilter(T, input[Ct+1:end]))
        else
            return constructGeneralFilter(T, input[Ct+1:end])
        end
    end

    S = match(r"^fn[:=](.+)$", input)
    if S !== nothing
        query = string(S.captures[1])
        return EvalFilter(T, query)
    end

    return constructFilter(T, input)
end

function applyFilter(oldList, pFilter :: Filter{T}, params...) where T
    N = length(oldList)
    newList = T[]
    
    for entry in oldList
        if (pFilter.fn)(entry, params...)
            push!(newList, entry)
        end
    end

    if length(newList) < N
        return newList, pFilter.desc
    else
        return newList, ""
    end
end