global GlobalDebugMode = false # Can only be turn on in Julia Mode.

function ForceReloadDebug(Query, DebugMode = false)
    global GlobalDebugMode
    if GlobalDebugMode
        DebugMode = true
    end
    
    if DebugMode
        prompt = DefaultPrompt(["yes", "no"], 2, Query)
        c = ask(prompt)
        return isYesInput(c)
    end
    return false
end

isYesInput(Str) = Str ∈ ["y", "Y", "yes", "Yes", "YES"]

function Beep()
    if Sys.iswindows()
        run(`powershell -Command "[console]::beep(600,300)"`)
    end
end