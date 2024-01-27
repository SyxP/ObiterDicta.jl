function getPanicEntry(id)
    LocalPanicDB = LocalizedData("PanicInfo")["dataList"]
    for entry in LocalPanicDB
        if entry["id"] == id
            return entry
        end
    end

    return nothing
end

function getPanicTitleStr(id; ThresholdLine = "")
    PanicData = getPanicEntry(id)
    
    Title = "Panic"
    if PanicData !== nothing && haskey(PanicData, "panicName")
        Title *= " Type: " * PanicData["panicName"] * " (" * @dim(string(id)) * ")"
    end

    io = IOBuffer()
    println(io, LineBreak(Title))
    StrInfo = String[]
    for (key, name) in [("lowMoraleDescription", "Low Morale"),
                        ("panicDescription", "Panic")]
        PanicData === nothing && continue
        if haskey(PanicData, key) && strip(PanicData[key]) != ""
            push!(StrInfo, "$(@blue(name)): " * getEscape(PanicData[key]))
        end
    end
    ThresholdLine != "" && println(io, ThresholdLine)
    print(io, justifyColumn(join(StrInfo, "\n")))

    return String(take!(io))
end

function getSanityFactorEntry(id)
    LocalMentalDB = LocalizedData("MentalCondition")["dataList"]
    for entry in LocalMentalDB
        if entry["id"] == id
            return entry
        end
    end
   
    return nothing
end

function getSanityFactorString(Factor :: String, type, sgn)
    filterFactor = filter(isAlpha, Factor)
    entry = getSanityFactorEntry(filterFactor)

    Ans = Factor
    if entry !== nothing && haskey(entry, type)
        S = eachmatch(r"(\d+)", Factor)
        Ans = replaceNumHoles([x.captures[1] for x in S], entry[type])
    end

    return "$sgn " * EscapeAndFlattenField(Ans)
end

function getPanicInfoStr(identity :: Personality, uptie)
    PanicID = getPanicType(identity)
    Ans = getPanicTitleStr(PanicID)

    Outcomes = String[]
    for (fn, type, sgn) in [(getPositiveSanityFactors, "add", "+"),
                            (getNegativeSanityFactors, "min", "-")]
        
        Tmp = fn(identity, uptie)
        if haskey(Tmp, "conditionIDList")
            for entry in Tmp["conditionIDList"]
                factor = entry["conditionID"]
                push!(Outcomes, getSanityFactorString(factor, type, sgn))
            end
        end
    end

    return vstack(Ans, join(Outcomes, "\n"))
end

function getPanicInfoStr(enemy :: RegularEnemyUnit)
    PanicID = getPanicType(enemy)

    panicThreshold = getPanicValue(enemy)
    lowMoraleThreshold = getLowMoraleValue(enemy)
    ThresholdStr = "$(@blue("Low Morale")) Threshold = $(@red(string(lowMoraleThreshold))). $(@blue("Panic")) Threshold = $(@red(string(panicThreshold)))."
    Ans = getPanicTitleStr(PanicID; ThresholdLine = ThresholdStr)

    Outcomes = String[]
    for (fn, type, sgn) in [(getPositiveSanityFactors, "add", "+"),
                            (getNegativeSanityFactors, "min", "-")]
        
        Tmp = fn(enemy)
        Tmp === nothing && continue
        Tmp == String[] && continue
        if haskey(Tmp, "conditionIDList")
            for entry in Tmp["conditionIDList"]
                factor = entry["conditionID"]
                push!(Outcomes, getSanityFactorString(factor, type, sgn))
            end
        end
    end

    return vstack(Ans, join(Outcomes, "\n"))
end

