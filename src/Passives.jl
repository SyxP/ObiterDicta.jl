const PossiblePassiveJSONClasses = ["passive"] 
# personality-passive is used to figure out the map Identity -> passive
function getPassiveJSONListFromStatic(dataClasses = PossiblePassiveJSONClasses)
    GetFileListFromStatic(dataClasses)
end

PassiveMasterList = Dict{String, Any}[]
function getPassiveMasterList()
    forceReload = ForceReloadDebug()
    
    global PassiveMasterList
    !forceReload && length(PassiveMasterList) != 0 && return PassiveMasterList
    
    for file in getPassiveJSONListFromStatic()
        append!(PassiveMasterList, StaticData(file)["list"])
    end
    return PassiveMasterList
end

function findExactInternalPassive(id; dontWarn = true)
    for PassiveList in getPassiveMasterList()
        if PassiveList["id"] == id
            return PassiveList
        end
    end
    
    dontWarn || @warn "Internal Passive with $id not found."
    return
end

function getLocalizedPassiveList()
    Files = getLocalizeDataInfo()["passive"]
    [LocalizedData(file) for file in Files]
end

function findExactLocalizedPassive(id; dontWarn = true)
    for PassiveList in getLocalizedPassiveList()
        length(PassiveList) == 0 && continue
        if haskey(PassiveList, "dataList")
            for Passive in PassiveList["dataList"]
                (Passive["id"] == id) && return Passive
            end
        else
            # Handle Special Case of File Irregularity
            @warn "Found a non-empty list of passives with no dataList."
        end
    end
    
    dontWarn || @warn "Localized Passive with $id not found."
    return
end

function PassivePair(id)
    LocalData = findExactLocalizedPassive(id)
    InterData = findExactInternalPassive(id)
    
    LocalData, InterData
end

function getPassiveName(PassivePair)
    LocalData, _ = PassivePair
    S = ""
    LocalData === nothing && return ""
    if haskey(LocalData, "name")
        S = LocalData["name"]
    end
    return S
end

function getPassiveDescription(PassivePair)
    LocalData, _ = PassivePair
    S = ""
    LocalData === nothing && return ""
    if haskey(LocalData, "desc")
        EscapedStr = replace(LocalData["desc"], "\n" => " ", r"<[^<>]*>" => "")
        S = @blue("Description: ") * EscapedStr 
    end
    return S
end

function getOtherFields(PassivePair)
    LocalData, InterData = PassivePair
    OtherFieldsio = IOBuffer()
    if LocalData !== nothing
        for (key, value) in LocalData
            if key ∈ ["name", "desc", "id"]
                continue
            end
            Tmp = value
            if Tmp isa Vector
                Tmp = join(string.(Tmp), ", ")
            end
            println(OtherFieldsio, "$(key) => $(Tmp)")
        end
    end
    if InterData !== nothing
        for (key, value) in InterData
            if key ∈ ["id", "attributeStockCondition", "attributeResonanceCondition"]
                continue
            end
            Tmp = value
            if Tmp isa Vector
                Tmp = join(string.(Tmp), ", ")
            end
            println(OtherFieldsio, "$(key) => $(Tmp)")
        end
    end
    return String(take!(OtherFieldsio))
end

function getPassiveID(PassivePair)
    LocalData, InterData = PassivePair
    if LocalData !== nothing && InterData !== nothing
        LocalData["id"] != InterData["id"] && @warn "Local and Internal ID do not match."
    end
    return LocalData["id"]
end

function getPassiveTitle(PassivePair)
    io = IOBuffer()
    print(io, @red("$(getPassiveName(PassivePair))"))
    print(io, " (")
    print(io, @blue("$(getPassiveID(PassivePair))"))
    print(io, ")")
    String(take!(io))
end

function getPassiveTriggerCondition(PassivePair)
    _, InterData = PassivePair
    S = String[]
    
    if haskey(InterData, "attributeResonanceCondition")
        Cond = InterData["attributeResonanceCondition"][1]
        push!(S, "Reson: " * getSinString(Cond["type"]) * " ×$(Cond["value"])")
    end
    if haskey(InterData, "attributeStockCondition")
        Cond = InterData["attributeStockCondition"][1]
        push!(S, "Owned: " * getSinString(Cond["type"]) * " ×$(Cond["value"])")
    end
    
    Ans = join(S, "{dim};{/dim} ")
    (Ans == "") && (Ans = "{red}No Condition{/red}")
    return Ans
end

function PassiveStringFromId(id)
    myPair = PassivePair(id)
    
    io = IOBuffer()
    contentArr = []
    push!(contentArr, getPassiveDescription(myPair))
    
    filter!(!=(""), contentArr)
    content = TextBox(join(contentArr, "\n"))
    
    OtherField = getOtherFields(myPair)
    if OtherField != ""
        LineBreak = hLine(93, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherField; width = 93, fit = false)
    end
    
    output = Panel(
    content,
    title = getPassiveTitle(myPair),
    subtitle = getPassiveTriggerCondition(myPair),
    subtitle_justify=:right,
    width = 100, 
    fit   = false)
    println(io, output)
    
    return String(take!(io))
end