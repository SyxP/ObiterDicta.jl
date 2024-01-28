struct Passive
    id :: Int
end

# personality-passive is used to figure out the map Identity -> passive
getMasterFileClasses(::Type{Passive}) = ["passive"]

PassiveMasterList = Passive[]
function getMasterList(::Type{Passive})
    getMasterList(Passive, PassiveMasterList)
end

getLocalizedFolders(::Type{Passive}) = ["passive"]

function getInternalVersion(myPassive :: Passive; dontWarn = !GlobalDebugMode)
    for PassiveList in getInternalList(Passive)
        for passive in PassiveList["list"]
            (passive["id"] == myPassive.id) && return passive
        end
    end

    dontWarn || @warn "Internal Passive with $(myPassive.id) not found."
    return
end

function getLocalizedVersion(myPassive :: Passive; dontWarn = !GlobalDebugMode)
    for PassiveList in getLocalizedList(Passive)
        if !haskey(PassiveList, "dataList")
            if (length(PassiveList) > 0)
                @warn "Unable to read Localized Passive List"
                return PassiveList
            end

            # Skipping Empty Passive List
            continue
        end

        for passive in PassiveList["dataList"]
            length(passive) == 0 && continue
            (passive["id"] == myPassive.id) && return passive
        end
    end
    
    dontWarn || @warn "Localized Passive with $(myPassive.id) not found."
    return
end

### Buff Specific Retrievals

getID(passive :: Passive) = passive.id
getStringID(passive :: Passive) = string(getID(passive))
getName(passive :: Passive) = getLocalizedField(passive, "name", "", "")
getDesc(passive :: Passive) = getLocalizedField(passive, "desc", nothing, "")

getEscapedDesc(passive :: Passive) = getEscape(getDesc, passive)

function hasResonanceCondition(myPassive :: Passive)
    Tmp = getInternalField(myPassive, "attributeResonanceCondition", nothing, nothing)
    return Tmp !== nothing
end
function hasStockCondition(myPassive :: Passive)
    Tmp = getInternalField(myPassive, "attributeStockCondition", nothing, nothing)
    return Tmp !== nothing
end
function getRequirement(myPassive :: Passive, sinStr)
    Ans = 0
    for fieldName in ["attributeResonanceCondition", "attributeStockCondition"]
        Tmp = getInternalField(myPassive, fieldName, nothing, nothing)
        if Tmp !== nothing
            for entry in Tmp
                !haskey(entry, "type") && continue
                (entry["type"] == sinStr) && (Ans += entry["value"])
            end
        end
    end

    return Ans
end

function getReqCondition(myPassive :: Passive)
    S = String[]
    
    for (fieldName, Label) in [("attributeResonanceCondition", "Reson"),
        ("attributeStockCondition", "Owned")]
        Tmp = getInternalField(myPassive, fieldName, nothing, nothing)
        if Tmp !== nothing
            Cond = Tmp[1]
            push!(S, "$Label: " * getSinString(Cond["type"]) * " ×$(Cond["value"])")
        end
    end
    
    Ans = join(S, "{dim};{/dim} ")
    (Ans == "") && (Ans = @red("No Condition"))
    return Ans
end

function getTitle(myPassive :: Passive)
    io = IOBuffer()
    print(io, @red(getName(myPassive)))
    print(io, " (")
    print(io, @blue(getStringID(myPassive)))
    print(io, ")")
    return String(take!(io))
end

function getTopLine(myPassive :: Passive)
    io = IOBuffer()
    for (fn, name) in [(getEscapedDesc, "Description")]
        Tmp = fn(myPassive)
        (Tmp !== nothing) && println(io, "$(@blue(name)): $Tmp")
    end
    
    return TextBox(String(take!(io)); width = 93, fit = false)
end

function getOtherFields(myPassive :: Passive)
    io = IOBuffer()
    if hasLocalizedVersion(myPassive)
        Ver = getLocalizedVersion(myPassive)
        for (key, value) in Ver
            if key ∈ ["name", "desc", "id"]
                continue
            end
            
            Tmp = EscapeAndFlattenField(value) 
            println(io, "$(key) => $(Tmp)")
        end
    end
    
    Ver = getInternalVersion(myPassive)
    if Ver !== nothing
        for (key, value) in Ver
            if key ∈ ["id", "attributeResonanceCondition", "attributeStockCondition"]
                continue
            end
            
            Tmp = EscapeAndFlattenField(value)
            println(io, "$(key) => $(Tmp)")
        end
    end
    
    return String(take!(io))
end

function PassivePanel(myPassive :: Passive; subtitle = "", overwriteSub = false)
    title = getTitle(myPassive)
    mySub = overwriteSub ? "" : getReqCondition(myPassive)
    mySub = String(strip(subtitle * " " * mySub))
    
    content = getTopLine(myPassive)
    OtherFields = getOtherFields(myPassive)
    if OtherFields != ""
        content /= LineBreak("Other Fields")
        content /= TextBox(OtherFields; width = 93, fit = false)
    end

    if mySub != ""
        return output = Panel(
            content,
            title = title, 
            subtitle = mySub,
            subtitle_justify = :right,
            width = 100,
            fit = false)
    else
        return output = Panel(
            content,
            title = title, 
            width = 100,
            fit = false)
    end
end

function toString(myPassive :: Passive)
    io = IOBuffer()
    println(io, PassivePanel(myPassive))
    return String(take!(io))
end