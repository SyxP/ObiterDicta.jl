FilterRegistry = Dict{String, Function}()

function RegisterFunction(Str, Fun)
    FilterRegistry[Str] = Fun
end

function FilterRegistryHelpStr()
    S = raw"""For use in filters, you may wish to use your own functions.
              You first write your function in Julia Mode. Then, you 
              register it with: `RegisterFunction(\"FilterName\", YourFn)`.

              You can list the registered filters with: `filtreg list`.
        """

    println(S)
    return S
end

function FilterRegistryParser(input)
    input == "list" && return printFilterRegistryList()
    
    @info "Unable to parse $input (try 'filtreg help')"
    return
end

FilterRegistryRegex = r"filtreg (.*)"
FiltRegCommand = Command(FilterRegistryRegex, FilterRegistryParser,
                         [1], FilterRegistryHelpStr)

function printFilterRegistryList()
    Names = keys(FilterRegistry)
    
    println(GridFromList(Names, 2; labelled = true))
    return FilterRegistry
end