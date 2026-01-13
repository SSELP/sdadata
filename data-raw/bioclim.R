# Tanzania data
# Load libraries
library(sf)
library(here)
library(dplyr)
sf_use_s2(FALSE)

# Create directory if not exist
ext_dir <- file.path(here(), "inst/extdata")
if(!dir.exists(ext_dir)) dir.create(ext_dir, recursive = TRUE)

districts <- st_read(file.path(ext_dir, "districts.geojson"))

# CHELSA data
# I have these layers somewhere else.
aoi <- st_bbox(districts) %>% st_as_sfc() %>% data.frame() %>% st_as_sf()
yr <- "1981-2010"
vars <- sprintf("bio%02d", 1:19)

# Define some functions
download_one <- function(url, dest) {
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)

    tryCatch({
        utils::download.file(url, destfile = dest, mode = "wb", quiet = TRUE)
        TRUE
    }, error = function(e) {
        FALSE
    })}

delete_downloads <- function(data_dir) {

    if (!dir.exists(data_dir)) return(invisible(TRUE))

    ok <- tryCatch({
        unlink(data_dir, recursive = TRUE, force = TRUE)
        TRUE
    }, error = function(e) {
        FALSE
    })
    invisible(TRUE)
}

url_base <- "https://os.unil.cloud.switch.ch/chelsa02/chelsa/global/bioclim"

temp_dir <- file.path(here("data-raw"), "temp")
data_dir <- file.path(temp_dir, yr)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

dl_paths <- lapply(vars, function(v){
    fn <- sprintf("CHELSA_%s_%s_V.2.1.tif", v, yr)
    url <- paste(url_base, v, yr, fn, sep = "/")
    dest <- file.path(data_dir, fn)

    if (download_one(url, dest)){
        dest
    } else NULL
})

dl_paths <- unlist(dl_paths[!sapply(dl_paths, is.null)])

if (length(dl_paths) == length(vars)){
    clim <- rast(dl_paths)
    names(clim) <- vars
    clim <- crop(clim, aoi)

    fname <- file.path(ext_dir, "bioclim.tif")
    writeRaster(clim, fname, overwrite = TRUE)
} else {
    warning("Failed to download some layers.")
}

# Clean up
delete_downloads(temp_dir)
tmpFiles(current = TRUE, remove = TRUE)
gc()
