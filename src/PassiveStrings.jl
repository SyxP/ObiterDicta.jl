struct Passive
    id :: Int
end

# personality-passive is used to figure out the map Identity -> passive
getMasterFileClasses(::Type{Passive}) = ["passive"]

function handleDataFile(::Type{Passive}, MasterList, file)
    for item in StaticData(file)["list"]
        push!(MasterList, Passive(item["id"]))
    end
end

PassiveMasterList = Passive[]
function getMasterList(::Type{Passive})
    getMasterList(Passive, PassiveMasterList)
end

function getInternalList(::Type{Passive})
    Files = getMasterFileList(Passive)
    [StaticData(file) for file in Files]
end

function getLocalizedList(::Type{Passive})
    Files = getLocalizeDataInfo()["passive"]
    [LocalizedData(file) for file in Files]
end

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

function getEscapedDesc(passive :: Passive)
    Str = getDesc(passive)
    Str === nothing && return nothing
    for change in getSkillReplaceDict()
        Str = replace(Str, change)
    end
    return replace(Str, "\n" => " ", r"<[^<>]*>" => "")
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
    (Ans == "") && (Ans = "{red}No Condition{/red}")
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
        (Tmp !== nothing) && println(io, "{blue}$(name): {/blue} $Tmp")
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

function PassivePanel(myPassive :: Passive; subtitle = "")
    title = getTitle(myPassive)
    mysub = subtitle * " " * getReqCondition(myPassive)
    
    content = getTopLine(myPassive)
    OtherFields = getOtherFields(myPassive)
    if OtherFields != ""
        LineBreak = hLine(93, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherFields; width = 93, fit = false)
    end
    
    return output = Panel(
    content,
    title = title, 
    subtitle = mysub,
    subtitle_justify = :right,
    width = 100,
    fit = false)
end

function toString(myPassive :: Passive)
    io = IOBuffer()
    println(io, PassivePanel(myPassive))
    return String(take!(io))
end