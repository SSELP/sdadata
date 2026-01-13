# Download GBIF records
library(rgbif)
library(sf)
library(here)
library(dplyr)
sf_use_s2(FALSE)

# Create directory if not exist
ext_dir <- file.path(here(), "inst/extdata")
if(!dir.exists(ext_dir)) dir.create(ext_dir, recursive = TRUE)

# Query the data
big_five <- c("Loxodonta africana", "Panthera leo", "Panthera pardus",
              "Syncerus caffer", "Diceros bicornis")
download_job <- occ_download(
    pred_in("taxonKey", name_backbone_checklist(big_five)$usageKey),
    pred("occurrenceStatus", "PRESENT"),
    pred("country", "TZ"),
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred_not(pred_in("basisOfRecord", c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))),
    pred_gte("distanceFromCentroidInMeters", 10),
    pred("taxonomicStatus", "ACCEPTED"),
    pred_gte("year", 2000),
    format = "SIMPLE_CSV")

# Download and import the data
status <- occ_download_wait(download_job)
if (status$status == "SUCCEEDED"){
    d <- occ_download_get(download_job, path = here("data-raw"))
} else {
    warning(sprintf("The request %s.", status$status))
    d <- NULL
}

# Unzip file
unzip(d, exdir = here("data-raw"))

# Process the data
districts <- st_read(here("inst/extdata/districts.geojson"))
species <- read.delim(here(gsub(".zip", ".csv", d))) %>%
    select(family, species, decimalLatitude, decimalLongitude, month, year) %>%
    st_as_sf(coords = c("decimalLongitude", "decimalLatitude"), crs = 4326) %>%
    st_intersection(districts %>% st_union()) %>%
    cbind(st_coordinates(.)) %>%
    st_drop_geometry() %>% rename(x = X, y = Y)

file.remove(here(gsub(".zip", ".csv", d)))

# Get two outliers
download_job <- occ_download(
    pred_in("taxonKey", name_backbone_checklist(big_five)$usageKey),
    pred("occurrenceStatus", "PRESENT"),
    pred("country", "TZ"),
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred_not(pred_in("basisOfRecord", c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))),
    pred_gte("distanceFromCentroidInMeters", 10),
    pred("taxonomicStatus", "ACCEPTED"),
    pred_gte("year", 2000),
    format = "SIMPLE_CSV")

# Download and import the data
status <- occ_download_wait(download_job)
if (status$status == "SUCCEEDED"){
    d <- occ_download_get(download_job, path = here("data-raw"))
} else {
    warning(sprintf("The request %s.", status$status))
    d <- NULL
}

# Unzip file
unzip(d, exdir = here("data-raw"))

outliers <- read.delim(here(gsub(".zip", ".csv", d))) %>%
    filter(stateProvince %in% c("Chitipa", "Rumphi")) %>%
    slice(c(1, 3))
outliers <- outliers %>%
    select(family, species, decimalLatitude, decimalLongitude, month, year) %>%
    st_as_sf(coords = c("decimalLongitude", "decimalLatitude"), crs = 4326) %>%
    cbind(st_coordinates(.)) %>%
    st_drop_geometry() %>% rename(x = X, y = Y)

file.remove(here(gsub(".zip", ".csv", d)))

# Save out and clean
species <- rbind(species, outliers)
write.csv(species, file.path(ext_dir, "species.csv"), row.names = FALSE)
