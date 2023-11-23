using JSON, Downloads

# This file's goal is to get the new bundle information each week, from the `catalog_S1` file.
#
# 1. Put the catalog_S1
# 2. Run `DownloadBundles()` 
# 3. Use AssetRipper/AssetDumper on `localize_s1` and `static_s1` Bundles
#    to get the two folders `Localize` and `StaticData`
#

function parseCatalog(file = "$DataDir/src/catalog_S1.json") 
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

function CheckProposedLocation(Location) 
    # Check if Location exists. If not make the directory
    isdir(Location) && return
    mkdir(Location)
end

function DownloadBundle(bundleURL, bundleLocation =  "$DataDir/Bundles/")
    CheckProposedLocation(bundleLocation)
    filePath = bundleLocation * split(bundleURL, "/")[end]
    @info "Downloading $filePath"

    try
        io = open(filePath, "w")
        Downloads.download(bundleURL, io)
        close(io)
    catch _
        @info "Failed to download $filePath"
        return false
    end

    return true
end

function DownloadAllBundles(bundleLocation = "$DataDir/Bundles/")
    URLs = parseCatalog()
    for url in URLs
        DownloadBundle(url, bundleLocation)
        sleep(0.2) # To not overwhelm the server
    end
end

function DownloadDataBundles(bundleLocation = "$DataDir/Bundles/")
