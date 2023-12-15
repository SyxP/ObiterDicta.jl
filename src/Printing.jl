function DisplaySkillAsTree(SkillDict, Title = "")

    myDict = deepcopy(SkillDict)
    if haskey(myDict, "ability")
        Title *= " (" * @red(myDict["ability"])
        if haskey(myDict, "value")
            Title *= ", $(@yellow("value")) ⇒ " * @blue(string(myDict["value"]))
            delete!(myDict, "value")
        end
        Title *= ")"
        delete!(myDict, "ability")
    end
    if haskey(myDict, "scriptName")
        S = myDict["scriptName"]
        (length(S) > 55) && (Title *= "\n")
        if length(S) > 80
            S = S[1:60] * "\n" * (" "^length("(Script:  ")) * S[61:end]
        end
        Title *= " (Script: " * @red(S) * ")"
        delete!(myDict, "scriptName")
    end

    function pn(io, node; kw...)
        # https://github.com/FedeClaudi/Term.jl/issues/206
        if node == myDict
            print(io, Title)
        elseif node isa AbstractDict
            print(io, string(typeof(node)))
        elseif node isa AbstractVector
            print(io, string(typeof(node)))
        else
            print(io, node)
        end
    end
    Term.Tree(myDict; print_node_function = pn)
end

function replaceSkillTag(str = clipboard())
    for change in getSkillReplaceDict()
        str = replace(str, change)
    end
    return replace(str, "\n" => " ", r"<[^<>]*>" => "")
end

function EscapeString(str = clipboard())
    nStr = strip(replace(str, "{" => "[[", "}" => "]]"))
    nStr = replace(nStr, r"</?[a-zA-Z=%0-9]+>" => "")
    return nStr
end

function EscapeAndFlattenField(value)
    if value isa Vector
        return "["*join(string.(value), ", ")*"]"
    else
        return EscapeString(string(value))
    end
end

function NumberStringWithSign(n)
    (n < 0 ? "" : "+") * string(n)
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

isAlpha(c) = ('a' ≤ c ≤ 'z') || ('A' ≤ c ≤ 'Z')
function replaceNumHoles(inputStr, holedStr; PercentageFlag = false)
    Ans = holedStr
    for (idx, val) in enumerate(inputStr)
        PercentageFlag && (Ans = replace(Ans, "{$(idx - 1)}%" => "$(100val)%"))
        Ans = replace(Ans, "{$(idx - 1)}" => val)
    end

    return Ans
end

LineBreak(S) =  hLine(93, "{bold white}$S{/bold white}", box = :DOUBLE)
