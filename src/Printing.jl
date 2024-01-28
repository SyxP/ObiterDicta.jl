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

function ReconstructSlotList(VectorSlotList)
    if VectorSlotList isa AbstractVector
        NewDict = Any[]
        for (idx, entry) in enumerate(VectorSlotList)
            if entry isa AbstractDict
                if haskey(entry, "chance") && 
                   haskey(entry, "skillChildList")
                    
                    SkillList = entry["skillChildList"]
                    StringList = String[]
                    for skillEntry in SkillList
                        combatSkill = CombatSkill(skillEntry["skillID"])
                        combatChance = skillEntry["chance"]
                        combatSkillName = getName(combatSkill)
                        (combatSkillName === nothing) && (combatSkillName = "")

                        outputStr = "(" * @blue(combatSkillName) * ", $combatChance)"
                        push!(StringList, outputStr)
                    end

                    ChanceNum = entry["chance"]
                    return "Chance = $ChanceNum; " * join(StringList, ", ")
                end
            end        
            
            length(keys(entry)) != 1 && return deepcopy(VectorSlotList)
            entryName = collect(keys(entry))[1]
            newKey = "$entryName $idx"
            newEntry = entry[entryName]

            push!(NewDict, ReconstructSlotList(entry[entryName]))
        end
        return NewDict
    end
        
    return deepcopy(VectorSlotList)
end

function DisplaySlotListAsTree(SlotList, Title = "")
    myDict = ReconstructSlotList(SlotList)
    
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

function completeStrip(str)
    strip(remove_decorations(str))
end

function EscapeString(str = clipboard())
    nStr = strip(replace(str, "{" => "[[", "}" => "]]"))
    nStr = replace(nStr, r"</?[a-zA-Z=%0-9\" #]+>" => "")
    nStr = replace(nStr, r"  +" => " ")
    return strip(nStr)
end

function EscapeAndFlattenField(value)
    if value isa Vector
        return "["*join(string.(value), ", ")*"]"
    else
        return EscapeString(string(value))
    end
end

function getEscape(fn, x)
    return getEscape(fn(x))
end
function getEscape(str :: String)
    str === nothing && return nothing
    return EscapeString(replaceSkillTag(str))
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

function justifyColumn(Str, ScreenWidth = 85)
    ArrayText = []
    Curr = firstindex(Str)
    if textwidth(Str) > ScreenWidth
        for c in eachindex(Str)
            if c == lastindex(Str)
                push!(ArrayText, Str[Curr:((Str[c] == '\n') ? prevind(Str, c) : c)])
            elseif Str[c] == '\n'
                push!(ArrayText, Str[Curr:prevind(Str, c)])
                Curr = nextind(Str, c)
                continue
            end

            textwidth(Str[Curr:c]) < ScreenWidth && continue
            getLangMode() == "en" && Str[c] != ' ' && continue
            
            push!(ArrayText, Str[Curr:prevind(Str, c)])
            Curr = c
        end
    end

    return join(strip.(ArrayText), "\n")
end