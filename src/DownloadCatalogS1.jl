"""
    This downloads the catalog_s1.json into the source repository.
    A non-exhaustive list of all the previous catalog_s1:
"""

# https://steamdb.info/depot/1973531/history/
# The folder in StreamingAssets/aa change shows new site.

getCatalogS1Versions() = readlines(joinpath(DataDir, "CatalogS1Versions.txt"))

function downloadCatalogS1JSON(catalogURL)
    URL = "https://d7g8h56xas73g.cloudfront.net/" * catalogURL * "/catalog_S1.json"
    @info "Downloading $(URL)."
    Downloads.download(URL, "$DataDir/catalog_S1.json")
end

getLatestCatalogS1() = getCatalogS1Versions()[end]
downloadLatestCatalogS1() = downloadCatalogS1JSON(getLatestCatalogS1())
function downloadNCatalogS1(N)
    Nth = parse(Int, N)
    CatalogS1Versions = getCatalogS1Versions()
    if !(1 ≤ Nth ≤ length(CatalogS1Versions))
        @info "There are only $(length(CatalogS1Versions)) entries in the current catalog_s1 database. You asked for the $Nth-th entry."
        return
    end

    downloadCatalogS1JSON(CatalogS1Versions[Nth])
end

function getAccessKey()
    io = open("$DataDir/BundleAccessKey.txt", "r")
    key = readline(io)
    close(io)
    
    return key
end

function uploadBundleFile(bundleFilePath, name)
    @info "Uploading $name ($bundleFilePath)"
    io = open(bundleFilePath)
    HashStr = uppercase(bytes2hex(open(bundleFilePath) do f
        sha2_256(f)
    end))
    Header = ["Checksum"  => HashStr,
              "AccessKey" => getAccessKey()]
    HTTP.put("https://sg.storage.bunnycdn.com/limbus-company-bundle/$name", Header, io)
    close(io)
end

function uploadAllBundles(filePath = "$git_download_cache/Bundles/")
    @info "Uploading $filePath"
    N = length(splitpath(filePath))
    
    for (root, dirs, files) in walkdir(filePath)
        for file in files
            filePath = joinpath(root, file)
            nameOfFile = join(splitpath(filePath)[(N+1):end], "/")
            uploadBundleFile(filePath, nameOfFile)
        end
    end
end

function getOriginURL()
    if GlobalDebugMode && isfile("$DataDir/BundleURL.txt")
        io = open("$DataDir/BundleURL.txt", "r")
        URL = readline(io)
        close(io)
        return URL
    end
    return "https://d7g8h56xas73g.cloudfront.net"
end

function autoPackageBundle(N = length(CatalogS1Versions))
    if !(1 ≤ N ≤ length(CatalogS1Versions))
        @info "There are only $(length(CatalogS1Versions)) entries in the current catalog_s1 database. You asked for the $N-th entry."
        return
    end

    catalogURL = CatalogS1Versions[N]
    Location   = "$git_download_cache/Bundles/$catalogURL/"
    println("Auto Packaging $catalogURL at $Location.")
    
    URL = "https://d7g8h56xas73g.cloudfront.net/" * catalogURL * "/catalog_S1.json"
    CheckProposedLocation(Location)
    Downloads.download(URL, "$Location/catalog_S1.json")

    downloadCatalogS1JSON(CatalogS1Versions[N])
    DownloadAllBundles()
    
    uploadAllBundles()
    Beep() ## Notify Long running process is done.
end

function checkFile(file)
    if !isfile(file)
        @error "File $file does not exist."
        return false
    end
    return true
end

function cleanUpBundleFolder(location = "$git_download_cache/Bundles/")
    @info "Cleaning Up $location."
    
    Flag = true
    while Flag
        Flag = false
        for (root, dirs, files) in walkdir(location)
            if length(files) + length(dirs) == 0
                rm(root)
                Flag = true
            end 
        end
    end
    return
end

function checkPackageBundle(N = length(CatalogS1Versions))
    if !(1 ≤ N ≤ length(CatalogS1Versions))
        @info "There are only $(length(CatalogS1Versions)) entries in the current catalog_s1 database. You asked for the $N-th entry."
        return
    end

    catalogURL = CatalogS1Versions[N]
    bundleLocation = "$git_download_cache/Bundles"
    Location   = "$bundleLocation/$catalogURL"
    checkFile("$Location/catalog_S1.json")
    
    downloadCatalogS1JSON(CatalogS1Versions[N])
    URLs = parseCatalog()
    for url in URLs
        filePath = getFilePathFromBundleURL(url, bundleLocation)
        checkFile(filePath)
    end

    return
end

function forceDownloadCatalogS1(URL)
    @info "Downloading from $(URL)"
    Downloads.download(string(URL), "$DataDir/catalog_S1.json")
end 

function appendNewCatalogS1Version(URL)
    open(joinpath(DataDir, "CatalogS1Versions.txt"), "a") do io
        print(io, "\n"*URL)
    end
end