function DisplaySkillAsTree(SkillDict, Title = "")

    myDict = deepcopy(SkillDict)
    if haskey(myDict, "ability")
        Title *= " (" * @red(myDict["ability"])
        if haskey(myDict, "value")
            Title *= ", {yellow}value{/yellow} ⇒ " * @blue(string(myDict["value"]))
            delete!(myDict, "value")
        end
        Title *= ")"
        delete!(myDict, "ability")
    end

    function pn(io, node; kw...)
        # https://github.com/FedeClaudi/Term.jl/issues/206
        if node == myDict
            print(io, Title)
        elseif node isa AbstractDict
            print(io, string(typeof(node)))
        else
            print(io, node)
        end
    end
    Term.Tree(myDict; print_node_function = pn)
end

function EscapeString(Str)
    replace(Str, "{" => "[[", "}" => "]]")
end

function GridFromList(StringList, columns = 1; labelled = false)
    n = ceil(Int, log10(1 + length(StringList)))
    StringCols = fill("", columns)

    for (i, Str) in enumerate(StringList)
        Prefix = labelled ? "{dim}$(lpad(i, n)){/dim} " : ""
        StringCols[mod1(i, columns)] *= Prefix * EscapeString(Str) * "\n"
    end
    
    GridList = [TextBox(rstrip(Str), fit = true, padding = Padding(0, 0, 0, 0)) for Str in StringCols]
    return grid(GridList; layout=(nothing, columns))
end