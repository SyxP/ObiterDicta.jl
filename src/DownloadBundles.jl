using JSON, Downloads

# This file's goal is to get the new bundle information each week, from the `catalog_S1` file.

function parseCatalog(file = "$DataDir/catalog_S1.json") 
    # Read file
    io = open(file, "r")
    CatalogJSON = JSON.parse(read(io, String))
    close(io)
    
    # Extract URLS from file
    URLs = typeof(CatalogJSON)()
    try
        URLs = CatalogJSON["m_InternalIds"]
        filter!(x -> x[1:5] == "https", URLs) # A little hacky trick to check if a string is a URL
    catch _
        @error "Catalog JSON $file format unparseable"
    end

    return URLs
end

CheckProposedLocation(Location) = mkpath(dirname(Location))

function getFilePathFromBundleURL(bundleURL, bundleLocation, URLBase = "https://d7g8h56xas73g.cloudfront.net")
    bundleURLParts = split(bundleURL, "/")
    urlBaseParts = split(URLBase, "/")
    fileName = bundleURLParts[(length(urlBaseParts) + 1) : end]
    dirPath = joinpath(bundleLocation, fileName[begin:(end - 1)]...)
    filePath = joinpath(bundleLocation, fileName...)

    filePath, dirPath
end

function DownloadBundle(bundleURL, bundleLocation) 
    filePath, dirPath = getFilePathFromBundleURL(bundleURL, bundleLocation)
    isfile(filePath) && return true
    CheckProposedLocation(dirPath)
    @info "Downloading $filePath"

    try
        io = open(filePath, "w")
        Downloads.download(bundleURL, io)
        close(io)
    catch _
        @info "Failed to download $filePath"
        return false
    end

    return filePath
end

function DownloadAllBundles(bundleLocation = "$git_download_cache/Bundles/")
    @info "Downloading to $bundleLocation"
    
    URLs = parseCatalog()
    for url in URLs
        newSource = getOriginURL()
        if newSource == "https://d7g8h56xas73g.cloudfront.net"
            DownloadBundle(url, bundleLocation)
            sleep(0.2) # Not overwhelm PMoon Server
        else
            newURL = replace(url, "https://d7g8h56xas73g.cloudfront.net" => newSource)
            DownloadBundle(newURL, bundleLocation)
        end
    end
end

function getDataURLs()
    URLs = parseCatalog()
    return filter(x -> match(r"localize|static", x) !== nothing, URLs)
end

function DownloadDataBundles(bundleLocation = "$git_download_cache/Bundles/")
    @info "Downloading to $bundleLocation"

    for url in getDataURLs()
        DownloadBundle(url, bundleLocation)
        sleep(0.2) # To not overwhelm the server
    end
end

function getFileHashes(bundleLocation)
    HashList = String[]
    for (root, dirs, files) in walkdir(bundleLocation)
        for file in files
            filePath = joinpath(root, file)
            HashStr = uppercase(bytes2hex(open(filePath) do f
                sha2_256(f)
            end))

            push!(HashList, HashStr)
        end
    end

    return HashList
end

function DownloadNewBundles(bundleLocation = "$git_download_cache/Bundles/")
    @info "Downloading to $bundleLocation"

    HashList = getFileHashes(bundleLocation)
    URLs = parseCatalog()
    for url in URLs
        fileLocation = DownloadBundle(url, bundleLocation)
        sleep(0.2) # To not overwhelm the server
        if fileLocation != false
            bundleHash = uppercase(bytes2hex(open(fileLocation) do f
                sha2_256(f)
            end))

            if (bundleHash ∈ HashList)
                @info "Found Hash in Hashlist $fileLocation"
                rm(fileLocation)
            end
        end
    end

    cleanUpBundleFolder(bundleLocation)
    return
end

function DownloadNBundleFromCatalog(n, bundleLocation = "$git_download_cache/Bundles/")
    @info "Downloading to $bundleLocation"
    CatalogList = parseCatalog()

    bundleNumber = parse(Int, n)
    if !(1 ≤ bundleNumber ≤ length(CatalogList))
        @info "There are only $(length(CatalogList)) entries in the current catalog_s1 database. You asked for the $bundleNumber-th entry."
        return
    end

    bundleURL = CatalogList[bundleNumber]
    DownloadBundle(bundleURL, bundleLocation)
end

function nameBundlesFromCatalog(catalogFile)
    URLs = parseCatalog(catalogFile)
    Names = Tuple{String, String}[]
    for url in URLs
        bundleName = split(url, "/")[end]
        Parts = split(bundleName, "_")[begin:(end - 1)]
        push!(Names, (join(Parts, "_"), url))
    end

    return Names
end

function listBundlesFromCatalog(catalogFile = "$DataDir/catalog_S1.json")
    println("Printing the bundles from $catalogFile")
    
    nameCatalog = nameBundlesFromCatalog(catalogFile)
    Names = [x[1] for x in nameCatalog]
    println(GridFromList(Names, 2; labelled = true))
    return [x[2] for x in nameCatalog]
end

function DownloadNameBundleFromCatalog(query, catalogFile = "$DataDir/catalog_S1.json", bundleLocation = "$git_download_cache/Bundles/")
    tprintln("Using {red}$query{/red} as query")
    result = SearchClosestString(query, nameBundlesFromCatalog(catalogFile))
    tprintln("The closest match was {red}$(result[1][1]){/red}.")

    downloadQuery = ForceReloadDebug("Would you like to download?", true)
    if downloadQuery
        @info "Downloading to $bundleLocation"
        DownloadBundle(result[1][2], bundleLocation)
    end
    return result
end

function DeleteDataFiles()
    for SubDir in ["StaticData/", "Localize/en", "Localize/jp", "Localize/kr"]
        targetDir = joinpath(DataDir, SubDir)
        rm(targetDir; recursive = true, force = true)
    end
    rm(joinpath(DataDir, "Localize", "RemoteLocalizeFileList.json"); force = true)
    rm(joinpath(git_download_cache, "Unbundled Data"); force = true, recursive = true)
    return
end

function UpdateDataFilesFromCatalogS1()
    # This does everything pseudo-automatically magically
    # It might break if the internal structure changes
    # It might also break with other edits to this file

    DownloadDataBundles()
    DeleteDataFiles()
    
    @eval using UnityPy
    bundleLocation = joinpath(git_download_cache, "Bundles")
    unzipLocation = joinpath(git_download_cache, "Unbundled Data") 
    for file in getDataURLs()
        filepath, _ = getFilePathFromBundleURL(file, bundleLocation)
        @info filepath 
        LoadTextBundle(filepath, unzipLocation)
    end

    NewHome = joinpath(unzipLocation, "Assets", "Resources_moved")
    for (root, _, files) in walkdir(NewHome)
        for file in files
            absPath = joinpath(root, file)
            fileName = relpath(absPath, NewHome)
            target = joinpath(DataDir, fileName)
            CheckProposedLocation(target)
            mv(absPath, joinpath(DataDir, fileName))
        end
    end

    cleanUpBundleFolder(unzipLocation)
end