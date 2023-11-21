module ObiterDicta
    using ReplMaker
    using Term, Term.Layout, Term.Prompts
    using StringDistances
    using JSON

    function MainParser(input)
        Commands = [SetLangCommand, HelpCommand, EXPCommand, BuffCommand]
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
                  buff (Status Effects)
    
                  For more information you can use `[command] help`
            """
        println(S)
    end

    # Back End Functions
    include("Command.jl")
    include("Printing.jl")
    include("LanguageInternalization.jl")
    include("DebugFunctions.jl")   
    
    # Contains File Retrieval and String Searching
    include("Utilities.jl")

    # Utility Modes
    include("ExperienceLevels.jl")
    include("Buffs.jl")
    include("Passives.jl")
   
    function StartREPL()
        initrepl(MainParser, 
             prompt_text="Limbus Query> ",
             prompt_color = :blue, 
             start_key=')', 
             mode_name="Limbus_mode",
             show_function=(args...) -> nothing)    
    end

    export StartREPL
end
