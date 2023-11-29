function getPanicEntry(id)
    LocalPanicDB = LocalizedData("PanicInfo")["dataList"]
    for entry in LocalPanicDB
        if entry["id"] == id
            return entry
        end
    end

    return nothing
end

function getPanicTitleStr(id)
    PanicData = getPanicEntry(id)
    
    Title = "Panic"
    if PanicData !== nothing && haskey(PanicData, "panicName")
        Title *= " Type: " * PanicData["panicName"]
    end

    Ans = LineBreak(Title)
    StrInfo = String[]
    for (key, name) in [("lowMoraleDescription", "Low Morale"),
                        ("panicDescription"), "Panic"]
        if haskey(PanicData, key) && strip(PanicData[key]) != ""
            push!(StrInfo, "$name: " * strip(PanicData[key]))
        end
    end

    return Ans * join(StrInfo, "\n")
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
        Ans = replaceRegexNumHoles(Factor, entry[type])
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

