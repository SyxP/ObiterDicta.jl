function BuffHelp()
    S = raw"""Looks up Buffs (Status Effects). Available Commands:
              !v/!verbose  - Outputs the internal buff data. (*)
              !l/!list     - Lists all the buffs. (*)
              !top_num_    - Outputs the top _num_ buffs matching the query. Default is 5. (*)
              !i/!internal - Only performs the query on internal buff names.
              !in:_loc_/@_loc_ - Restricts the search to buffs originating from _loc_.
              Possible _loc_s : md, md1, md2, md2n, md2h, rr, rr1, rr2
              
              (*) commands can not be combined. Example usage:
              `buff bleed !top !in:rr` - Outputs the top 5 Refraction Railway bleed buffs.
              `buff eviscerate !i !v`  - Outputs the internal buff Eviscerate and its internal IDs.
        """
    println(S)
end

function getInternalBuffList()
    [StaticData("buff/$(file[begin:end-5])") for file in readdir("data/StaticData/static-data/buff")]
end

function getLocalizedBuffList()
    Files = ["Bufs", "Bufs-a1c5p1", "Bufs_Refraction2"]
    [LocalizedData(file) for file in Files]
end

function findExactInternalBuff(id)
    for BuffList in getInternalBuffList()
        for Buff in BuffList["list"]
            (Buff["id"] == id) && return Buff
        end
    end
    @warn "Internal Buff with $id not found."
    return
end

function getMaxStacks(Buff)
    return haskey(Buff, "maxStack") ? Buff["maxStack"] : 99
end

function getBuffClass(Buff)
    return haskey(Buff, "buffClass") ? Buff["buffClass"] : "No Class"
end

function InternalBuffString(id)
    Buff = findExactInternalBuff(id)
    if Buff === nothing
        return ""
    end
    io = IOBuffer()

    Title = "{red} $(Buff["id"]) {/red} ({blue} $(getBuffClass(Buff)) {/blue}: Max Stacks = $(getMaxStacks(Buff)))"
    TopLine = Vector{Panel}()

    haskey(Buff, "buffType") && (push!(TopLine, TextBox("Buff Type => $(Buff["buffType"])"; fit = true)))
    haskey(Buff, "canBeDespelled") && (push!(TopLine, TextBox("Can Be Despelled => $(Buff["canBeDespelled"])"; fit = true)))
    haskey(Buff, "iconId") && (push!(TopLine, TextBox("Icon ID => $(Buff["iconId"])"; fit = true)))
    while length(TopLine) < 3
        push!(TopLine, TextBox(""; fit = true))
    end
    content = grid(TopLine; layout=(nothing, 3))

    OtherFieldsio = IOBuffer()
    for (key, value) in Buff
        if key ∈ ["buffType", "canBeDespelled", "id", "buffClass", "maxStack", "list", "iconId"]
            continue
        end
        println(OtherFieldsio, "$(key) => $(value)")
    end

    OtherField = String(take!(OtherFieldsio))
    if OtherField != ""
        LineBreak = hLine(93, "{bold white}Other Fields{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        content /= TextBox(OtherField ; fit = true)
    end

   

    Actions = Buff["list"]
    if length(Actions) > 0
        LineBreak = hLine(94, "{bold white}Actions{/bold white}"; box=:DOUBLE)
        content /= LineBreak
        for (i, Action) in enumerate(Actions)
            content /= DisplaySkillAsTree(Action, "Action $i")
        end
    end
    
    
    output = Panel(
        content,
        title = Title,
        width = 100, 
        fit   = false)
    println(io, output)
    String(take!(io))
end

function LocalizedBuffString(id)

end