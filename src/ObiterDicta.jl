module ObiterDicta
    using ReplMaker
    using Term, Term.Layout

    function MainParser(input)
        Commands = [SetLangCommand, HelpCommand, EXPCommand]
        for command in Commands
            S = CheckCommand(command, input)
            S == false || return S
        end
        @info "Unable to parse $input"
        return
    end

    function getHelp()
        S = raw"""Available Commands:
                  lang (Set Language)
                  exp (Experience Levels)
    
                  For more information you can use `[command] help`
            """
        println(S)
    end
    
    include("Utilities.jl")
    include("ExperienceLevels.jl")
    include("Buffs.jl")
    
    initrepl(MainParser, 
             prompt_text="Limbus Query> ",
             prompt_color = :blue, 
             start_key=')', 
             mode_name="Limbus_mode",
             show_function=(args...) -> nothing)    
end
