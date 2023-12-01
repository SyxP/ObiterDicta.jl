# The purpose of this file is to ease in the updating process of translations.
# After updating, `git push` /  make a pull request.
# This code will modify the base directory.

function UpdateBundleHelp()
    S = raw"""Updates data/ and Downloads bundles from catalog_S1.json.
              These commands will fetch the files from the internet.
              `update CN`   - Updates Chinese data files.
              `update RU`   - Updates Russian data files.
              `update main` - Updates English/Korean/Japanese data files from PMoon source.
              `update all`  - Updates all data files. (Currently only CN and RU)

              `update list bundles`         - List available bundles. 
              `update catalog _num_`        - Downloads _num_th bundle. If _num_ is not given, downloads the latest bundle.     
              `update catalog force _url_`  - Downloads the bundle at _url_ to replace the Catalog_S1 file

              `update bundle _bundle_name_` - Downloads _bundle_name_ to scratch.
              `update bundle all`           - Downloads all bundles. (warning: ~9GB)
              `update bundle new`           - Downloads only new bundles, not in your folder. 
              `update bundle data`          - Downloads only `static_s1` and `localize_s1`.
              `update bundle _num_`         - After list, download _num_th bundle.
              """
    
    println(S)
end

function UpdateBundleParser(input)
    input == "CN"  && return updateCN()
    input == "RU"  && return updateRU()
    input == "main" && return UpdateDataFilesFromCatalogS1()
    input == "all" && return updateAll()

    input == "bundle all" && return DownloadAllBundles()
    input == "bundle new" && return DownloadNewBundles()
    input == "bundle data" && return DownloadDataBundles()
    input == "list bundles" && return listBundlesFromCatalog()

    S = match(r"^catalog force (.*)$", input)
    if S !== nothing
        return forceDownloadCatalogS1(S.captures[1])
    end

    S = match(r"^catalog ([1-9][0-9]*)$", input)
    if S !== nothing
        return downloadNCatalogS1(S.captures[1])
    end
    input == "catalog" && return downloadLatestCatalogS1()

    S = match(r"^bundle ([1-9][0-9]*)$", input)
    if S !== nothing
        return DownloadNBundleFromCatalog(S.captures[1])
    end

    S = match(r"^bundle (.*)$", input)
    if S !== nothing
        return DownloadNameBundleFromCatalog(S.captures[1])
    end

    @info "Unable to parse $input (try `update help`)"
    return
end

UpdateBundleRegex = r"^update (.*)$"
UpdateBundleCommand = Command(UpdateBundleRegex, UpdateBundleParser, [1], UpdateBundleHelp)

function updateTranslation(lang, refSite)
    global git_download_cache
    llang, ulang = lowercase(lang), uppercase(lang)

    srcPath = joinpath(git_download_cache, llang)
    localPath = joinpath(DataDir, "Localize", llang)
    !isdir(localPath) && mkdir(localPath)

    if isdir(srcPath)
        run(`$(git()) -C $(srcPath) pull`)
    else
        mkdir(srcPath)
        run(`$(git()) clone $refSite $(srcPath)`)
    end

    newHome = joinpath(srcPath, "Localize", ulang)
    for (root, dirs, files) in walkdir(newHome)
        for dir in dirs
            path = joinpath(localPath, dir)
            !isdir(path) && mkdir(path)
        end
        Ct = length(newHome) + 1
        while Ct < length(root) && !(uppercase(root[Ct]) ∈ 'A':'Z')
            Ct += 1
        end
        currentFolder = root[Ct:end]

        
        for file in files
            Src = joinpath(root, file)
            Dest = joinpath(localPath, currentFolder, "$(ulang)_" * file)
            cp(Src, Dest, force = true)
        end
    end
end

updateCN() = updateTranslation("cn",
             "https://github.com/LocalizeLimbusCompany/LocalizeLimbusCompany")

updateRU() = updateTranslation("ru",
             "https://github.com/Crescent-Corporation/LimbusCompanyBusRUS")

function updateAll()
    updateCN()
    updateRU()
    UpdateDataFilesFromCatalogS1()
end

