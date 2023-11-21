global DebugMode = false # Can only be turn on in Julia Mode.

function ForceReloadDebug()
    forceReload = false
    if DebugMode
        prompt = DefaultPrompt(["yes", "no"], 2, "Would you like to force reload Buff Master List?")
        c = ask(prompt)
        isYesInput(c) && (forceReload = true)
    end
    return forceReload
end

isYesInput(Str) = Str ∈ ["y", "Y", "yes", "Yes", "YES"]
