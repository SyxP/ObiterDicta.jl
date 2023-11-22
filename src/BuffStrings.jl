struct Buff
    id :: String
end

# mirror-dungeon-floor-buff seems to be duplicated inside buff.
# TODO: The following Buff types are not supported ["panic-buff", "rail-Line2-buff"]
getMasterFileClasses(::Type{Buff}) = ["buff"]

function handleDataFile(::Type{Buff}, MasterList, file)
    for item in StaticData(file)["list"]
        push!(MasterList, Buff(item["id"]))
    end
end

const BuffMasterList = Buff[]
function getMasterList(::Type{Buff})
    getMasterList(Buff, BuffMasterList)
end

function getInternalList(::Type{Buff})
    Files = getMasterFileList(Buff)
    [StaticData(file) for file in Files]
end

function getLocalizedList(::Type{Buff})
    Files = getLocalizeDataInfo()["buf"]
    [LocalizedData(file) for file in Files]
end

function getInternalVersion(myBuff :: Buff; dontWarn = !DebugMode)
    for BuffList in getInternalList(Buff)
        for buff in BuffList["list"]
            (buff["id"] == myBuff.id) && return buff
        end
    end

    dontWarn || @warn "Internal Buff with $(myBuff.id) not found."
    return
end

function getLocalizedVersion(myBuff :: Buff; dontWarn = !DebugMode)
    for BuffList in getLocalizedList(Buff)
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
getMaxStacks(buff :: Buff) = getInternalField(buff, "maxStacks", 99, -1)
getBuffClass(buff :: Buff) = getInternalField(buff, "buffClass", "No Class", "")
getBuffType(buff :: Buff) = getInternalField(buff, "buffType", nothing, "")
getBuffDespelled(buff :: Buff) = getInternalField(buff, "canBeDespelled", nothing, "")
getIconID(buff :: Buff) = getInternalField(buff, "iconId", nothing, "")
getSummary(buff :: Buff) = getLocalizedField(buff, "summary", nothing, "")
getDesc(buff :: Buff) = getLocalizedField(buff, "desc", nothing, "")
getUndefinedStatus(buff :: Buff) = getLocalizedField(buff, "undefined", nothing, "")

function getInternalTitle(buff :: Buff)
    io = IOBuffer()
    print(io, "{red} $(getID(buff)) {/red} (")
    print(io, "{blue} $(getBuffClass(buff)) {/blue}")
    print(io, ": Max Stacks = $(getMaxStacks(buff)))")
    return String(take!(io))
end

function getLocalizedTitle(buff :: Buff)
    io = IOBuffer()
    print(io, "{red} $(getName(buff)) {/red} (")
    print(io, "{blue} $(getID(buff)) {/blue})")
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

function getLocalizedTopLine(buff :: Buff)
    io = IOBuffer()
    for (fn, name) in [(getSummary, "Summary"),
        (getDesc, "Description")]
        
        Tmp = fn(buff)
        (Tmp !== nothing) && println(io, "{blue}$(name): {/blue} $(Tmp)")
    end
    
    Tmp = getUndefinedStatus(buff)
    if Tmp !== nothing && Tmp == "-"
        println(io, "Has {blue}undefined{/blue} (\"-\") field.")
    end
    
    return TextBox(String(take!(io)))
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
        LineBreak = hLine(94, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherFields; width = 94, fit = false)
    end
    
    Actions = getActionList(buff)
    if length(Actions) > 0
        LineBreak = hLine(94, "{bold white}Actions{/bold white}"; box=:DOUBLE)
        content /= LineBreak
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
        LineBreak = hLine(94, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherFields; width = 94, fit = false)
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