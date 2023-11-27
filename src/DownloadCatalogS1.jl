"""
    This downloads the catalog_s1.json into the source repository.
    A non-exhaustive list of all the previous catalog_s1:
"""

CatalogS1Versions = [
    "StandaloneWindows64Cloud_0309_a"
    "StandaloneWindows64Cloud_0316_a"
    "StandaloneWindows64Cloud_0323_j"
    "StandaloneWindows64Cloud_0330_l"
    "StandaloneWindows64Cloud_0406_w"
    "StandaloneWindows64Cloud_0407_x"
    "StandaloneWindows64Cloud_0420_h"
    "StandaloneWindows64Cloud_0420_i"
    "StandaloneWindows64Cloud_0427_p"
    "StandaloneWindows64Cloud_0504_z"
    "StandaloneWindows64Cloud_0511_t"
    "StandaloneWindows64Cloud_0518_r"
    "StandaloneWindows64Cloud_0525_t"
    "StandaloneWindows64Cloud_0601_t"
    "s0608_VIGtz9TYQzVBCtah7QmD"
    "s0615_DRonIKinGuWs9XX3nkxB"
    "s0622_bQDi7I33t85PPqjJxrAs"
    "s0629_9nGfZ8NDAS5YlyXmmIvB"
    "s0706_cVisJt8vQsWrZjAFJPcV"
    "s0713_9Ls4-_512whD2RWW295Z"
    "s0720_Z0NIcgj5VjyqZH-EpeOM"
    # s0727 - s1109 are missing. TODO: Reconstruct the links via Steam Dump
    "s0914_zZ-TPEBYrTGBPUDO2Eim" 
    "s1116_GiWH7BIIPKvl98vphGaw"
    "s1123_TTSlH021Looc8jCZJ4-a"
]


function downloadCatalogS1JSON(catalogURL)
    URL = "https://d7g8h56xas73g.cloudfront.net/" * catalogURL * "/catalog_S1.json"
    @info "Downloading $(URL)."
    Downloads.download(URL, "$DataDir/catalog_S1.json")
end

downloadLatestCatalogS1() = downloadCatalogS1JSON(CatalogS1Versions[end])
function downloadNCatalogS1(N)
    Nth = parse(Int, N)
    if !(1 ≤ Nth ≤ length(CatalogS1Versions))
        @info "There are only $(length(CatalogS1Versions)) entries in the current catalog_s1 database. You asked for the $Nth-th entry."
        return
    end

    downloadCatalogS1JSON(CatalogS1Versions[Nth])
end