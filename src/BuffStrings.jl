struct Buff
    id :: String
end

# mirror-dungeon-floor-buff seems to be duplicated inside buff.
# TODO: The following Buff types are not supported ["panic-buff", "rail-Line2-buff"]
# TODO: BuffAbilities only exist in localized form, but not in internal form. They are wrapped in other Buffs.
getMasterFileClasses(::Type{Buff}) = ["buff"]

const BuffMasterList = Buff[]
function getMasterList(::Type{Buff})
    getMasterList(Buff, BuffMasterList)
end

getLocalizedFolders(::Type{Buff}) = ["buf"]

function getInternalVersion(myBuff :: Buff; dontWarn = !GlobalDebugMode)
    for BuffList in getInternalList(Buff)
        for buff in BuffList["list"]
            (buff["id"] == myBuff.id) && return buff
        end
    end

    dontWarn || @warn "Internal Buff with $(myBuff.id) not found."
    return
end

function getLocalizedVersion(myBuff :: Buff; dontWarn = !GlobalDebugMode)
    for BuffList in getLocalizedList(Buff)
        if !haskey(BuffList, "dataList")
            if GlobalDebugMode && length(keys(BuffList)) > 0
                @info "Unable to parse non-empty file $(BuffList)."
            end
            continue
        end
        for buff in BuffList["dataList"]
            (buff["id"] == myBuff.id) && return buff
        end
    end
    
    dontWarn || @warn "Localized Buff with $(myBuff.id) not found."
    return
end

### Buff Specific Retrievals

getID(buff :: Buff) = buff.id 
getName(buff :: Buff) = getLocalizedField(buff, "name", "", "")
getMaxStacks(buff :: Buff) = getInternalField(buff, "maxStack", 99, -1)
getBuffClass(buff :: Buff) = getInternalField(buff, "buffClass", "No Class", "")
getBuffType(buff :: Buff) = getInternalField(buff, "buffType", nothing, "")
getBuffDespelled(buff :: Buff) = getInternalField(buff, "canBeDespelled", nothing, "")
getIconID(buff :: Buff) = getInternalField(buff, "iconId", nothing, "")
getAttributeType(buff :: Buff) = getInternalField(buff, "attributeType", nothing, "")
getKeywordList(buff :: Buff) = getInternalField(buff, "categoryKeywordList", nothing, String[])
getSummary(buff :: Buff) = getLocalizedField(buff, "summary", nothing, "")
getDesc(buff :: Buff) = getLocalizedField(buff, "desc", nothing, "")
getUndefinedStatus(buff :: Buff) = getLocalizedField(buff, "undefined", nothing, "")

function getTitle(buff :: Buff)
    io = IOBuffer()
    S = getName(buff)
    if S !== ""
        print(io, @red(S))
        print(io, " (")
        print(io, @dim(@blue(getID(buff))))
        print(io, ")")
    else
        print(io, @blue(getID(buff)))
    end

    return String(take!(io))
end

function getInternalTitle(buff :: Buff)
    io = IOBuffer()
    print(io, " $(@red(getID(buff)))  (")
    print(io, " $(@blue(getBuffClass(buff))) ")
    print(io, ": Max Stacks = $(getMaxStacks(buff)))")
    return String(take!(io))
end

function getLocalizedTitle(buff :: Buff)
    io = IOBuffer()
    print(io, " $(@red(getName(buff)))  (")
    print(io, " $(@blue(getID(buff))) )")
    return String(take!(io))
end

function getInternalTopLine(buff :: Buff)
    TopLine = String[]
    for (fn, name) in [(getBuffType, "Buff Type"),
        (getBuffDespelled, "Can Be Despelled"),
        (getIconID, "Icon ID")]
        Tmp = fn(buff)
        (Tmp !== nothing) && push!(TopLine, "$(name) => $(Tmp)")
    end
    return GridFromList(TopLine, 3)
end

function guessLocalizedSummaryFromList(buff :: Buff)
    actionList = getActionList(buff)
    
    FileList = getLocalizeDataInfo()["buffAbilities"]
    function findEntry(ability)
        for file in FileList
            for buffAbility in LocalizedData(file)["dataList"]
                if buffAbility["id"] == ability
                    return buffAbility
                end
            end
        end
        return nothing
    end

    function getSummary(action)
        Tmp = findEntry(action["ability"])
        Tmp === nothing && return ""
        
        value = haskey(action, "value") ? action["value"] : "{0}"
        if haskey(action, "atk")
            attackStr = AttackTypes(action["atk"])
            return replaceNumHoles([attackStr, value], Tmp["variation"]) 
        elseif haskey(action, "attribute")
            attrStr = getSinString(action["attribute"])
            return replaceNumHoles([attrStr, value], Tmp["variation"])
        else
            HoledStr = Tmp["desc"]
            return occursin("{1}", HoledStr) ? HoledStr : replaceNumHoles([value], HoledStr; PercentageFlag = true)
        end
    end
        
    S = join(EscapeString.(getSummary.(actionList)), "\n")
    S *= "\n" * @red("Note") * ": Description determined from effects."
end

function getLocalizedTopLine(buff :: Buff)
    io = IOBuffer()
    for (fn, name) in [(getSummary, "Summary"),
        (getDesc, "Description")]
        
        Tmp = fn(buff)
        (Tmp !== nothing) && println(io, @blue(name) * ": $(EscapeString(Tmp))")
    end
    
    Tmp = getUndefinedStatus(buff)
    if Tmp !== nothing && Tmp == "-"
        println(io, "Has $(@blue("undefined")) (\"-\") field.")
    end
   
    S = String(take!(io))
    (S == "") && (S = guessLocalizedSummaryFromList(buff))

    return TextBox(S)
end

function getOtherFieldsInternal(buff :: Buff)
    InterVer = getInternalVersion(buff)
    InterVer === nothing && return ""
    
    io = IOBuffer()
    for (key, value) in InterVer
        if key ∈ ["buffType", "canBeDespelled", "id", "buffClass", "maxStack", "list", "iconId"]
            continue
        end
        
        if key == "attributeType"
            AdditionalInfo = "($(getSinString(value)))"
            println(io, "$(key) => $(value) $AdditionalInfo")
            continue
        end
        
        println(io, "$(key) => $(EscapeString(string(value)))")
    end
    
    return String(take!(io))
end

function getOtherFieldsLocalized(buff :: Buff)
    LocalVer = getLocalizedVersion(buff)
    io = IOBuffer()
    
    for (key, value) in LocalVer
        if key ∈ ["name", "summary", "desc", "id"]
            continue
        end
        
        if key == "undefined" && value == "-"
            continue
        end
        
        if key == "attributeType"
            AdditionalInfo = "($(getSinString(value)))"
            println(io, "$(key) => $(value) $AdditionalInfo")
            continue
        end
        
        println(io, "$(key) => $(EscapeString(string(value)))")
    end
    
    return String(take!(io))
end

getActionList(buff :: Buff) = getInternalField(buff, "list", Dict{String, Any}[], nothing)

### Pretty Printing

function InternalBuffPanel(buff :: Buff; subtitle = "")
    Title = getInternalTitle(buff)
    
    content = getInternalTopLine(buff)
    
    OtherFields = getOtherFieldsInternal(buff)
    if OtherFields != ""
        content /= LineBreak("Other Fields")
        content /= TextBox(OtherFields; width = 93, fit = false)
    end
    
    Actions = getActionList(buff)
    if length(Actions) > 0
        content /= LineBreak("Actions")
        for (i, Action) in enumerate(Actions)
            content /= DisplaySkillAsTree(Action, "Action $i")
        end
    end
    
    if subtitle != ""
        return output = Panel(
        content,
        title = Title,
        subtitle = subtitle,
        width = 100,
        fit = false)
    else
        return output = Panel(
        content,
        title = Title,
        width = 100,
        fit = false)
    end
end

function LocalizedBuffPanel(buff :: Buff; subtitle = "")
    hasLocalizedVersion(buff) || return ""
    
    Title = getLocalizedTitle(buff)
    
    content = getLocalizedTopLine(buff)
    
    OtherFields = getOtherFieldsLocalized(buff)
    if OtherFields != ""
        content /= LineBreak("Other Fields")
        content /= TextBox(OtherFields; width = 93, fit = false)
    end
    
    if subtitle != ""
        return output = Panel(
        content,
        title = Title,
        subtitle = subtitle,
        width = 100,
        fit = false)
    else
        return output = Panel(
        content,
        title = Title,
        width = 100,
        fit = false)
    end
end

function toString(buff :: Buff)
    io = IOBuffer()
    if hasLocalizedVersion(buff)
        println(io, LocalizedBuffPanel(buff))
    end
    println(io, InternalBuffPanel(buff))
    return String(take!(io))
end