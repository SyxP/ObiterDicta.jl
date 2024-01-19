struct Item
    id :: Int
end

struct UserTicket
    id :: Int
end

getMasterFileClasses(::Type{Item}) = ["item"]
getMasterFileClasses(::Type{UserTicket}) = ["userticket-l", "userticket-r", "userticket-egobg"]

ItemMasterList = Item[]
getMasterList(::Type{Item}) = getMasterList(Item, ItemMasterList)

UserTicketMasterList = UserTicket[]
getMasterList(::Type{UserTicket}) = getMasterList(UserTicket, UserTicketMasterList)

getLocalizedFolders(::Type{Item}) = ["item"]
getLocalizedFolders(::Type{UserTicket}) = ["userTicketL", "userTicketR", "userTicketEGOBg"]

# User Ticket comes in three items. We only pull information from the first one 
# we find. If in the future, the three things don't come together. One needs to split
# these.

# User Tickets have additional information (e.g. Refraction Railway displays the cycle (and loop number))
# This is found in StaticData\static-data\userbanner

for (dataType, name) in [(Item, "Item"), (UserTicket, "User Ticket")]
    @eval function getInternalVersion(myItem :: $dataType; dontWarn = !GlobalDebugMode)
        for ItemList in getInternalList($dataType)
            for entry in ItemList["list"]
                if entry["id"] == myItem.id
                    return entry
                end
            end
        end

        ErrorStr = "No Internal" * $(name) * " matching $(myItem.id) found."
        dontWarn || @info ErrorStr
        return
    end
end

for (dataType, name) in [(Item, "Item"), (UserTicket, "User Ticket")]
    @eval function getLocalizedVersion(myItem :: $dataType; dontWarn = !GlobalDebugMode)
        for ItemList in getLocalizedList($dataType)
            for entry in ItemList["dataList"]
                if entry["id"] == myItem.id
                    return entry
                end
            end
        end

        ErrorStr = "No Localized" * $(name) * " matching $(myItem.id) found."
        dontWarn || @info ErrorStr
        return
    end
end

### Retrival Functions
getID(myItem :: Item) = myItem.id
getID(myItem :: UserTicket) = myItem.id
getStringID(myItem :: Item) = string(myItem.id)
getStringID(myItem :: UserTicket) = string(myItem.id)

for (fn, field, default) in [(:getSpriteStr, "spriteStr", ""),
                             (:getCategory, "category", "")]
    @eval $fn(myItem :: Item) = getInternalField(myItem, $field, $default, $default)
end

for (fn, field, default) in [(:getDesc, "desc", ""),
                             (:getName, "name", "")]
    @eval $fn(myItem :: Item) = getLocalizedField(myItem, $field, $default, $default)
    @eval $fn(myItem :: UserTicket) = getLocalizedField(myItem, $field, $default, $default)
end

getFlavor(myItem :: Item) = getLocalizedField(myItem, "flavor", "", "")

# TODO: Printing of items

function getDropString(dropData :: Dict{String, Any})
    # Type, ID, Num
    typeString = dropData["type"]
    infoString = ""
    hasVerified = false
    for (lookupType, typeType) in [("ITEM", Item),
                                   ("USER_TICKET_DECO_LEFT", UserTicket),
                                   ("USER_TICKET_DECO_RIGHT", UserTicket),
                                   ("USER_TICKET_DECO_EGOBG", UserTicket)]
        if lookupType == typeString
            infoString = getName(typeType(dropData["id"]))
            hasVerified = true
        end
    end
    for (lookupType, typeType, prefix) in [("EGO", EGO, "E.G.O"),
                                   ("PERSONALITY", Personality, "Identity")]
        if lookupType == typeString
            infoString = prefix * " " * getTitle(typeType(dropData["id"]))
            hasVerified = true
        end
    end
    for (lookup) in [("USERBANNER")]
        # User Banners are Effects
        if lookup == typeString
            infoString = "User Banner Effect ($(dropData["id"]))"
            hasVerified = true
        end
    end
    if typeString == "USER_TICKET_DECO_LEFT"
        infoString *= " Left"
    elseif typeString == "USER_TICKET_DECO_RIGHT"
        infoString *= " Right"
    elseif typeString == "USER_TICKET_DECO_EGOBG"
        infoString *= " EGO Background"
    end
    hasVerified || @info "Unknown drop type $(typeString)."
    
    io = IOBuffer()
    if !(typeString ∈ ["USERBANNER", "USER_TICKET_DECO_EGOBG", "USER_TICKET_DECO_LEFT", "USER_TICKET_DECO_RIGHT"])
        print(io, string(dropData["num"]))
        print(io, @dim("x"))
        print(io, " ")
    end
    print(io, infoString)
    return String(take!(io))
end

function getDropString(dropData :: Vector{T}) where T
    dropStrings = getDropString.(dropData)
    return join(dropStrings, ", ")
end

raw"""
List of Events
> Tripbooking (Preregisration)
> New Manager Attendance (April Fool's) - data\StaticData\static-data\attendance-rewards
> Hell's Kitchen (3.5) - data\StaticData\static-data\hells-chicken-event
> Roll Call (3 Weeks Login Event) - data\StaticData\static-data\daily-login-event

The rest are in data\StaticData\static-data\event
> S.E.A (4.5) - umida-event.json
> Special Attendance (Month long) - daily-login-event-230907.json 
> Halloween - daily-login-event-2301026_Halloween.json
> 7th Anniversary - daily-login-event-2301118_7thAnniversary.json
> Miracle of District 20 (5.5) - miracleofdistrict20-event.json 
> Dawn of Green (2nd Walpurgisnacht) - Need to implement Missions explicitly
"""