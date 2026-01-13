# Tanzania data
# Load libraries
library(sf)
library(here)
library(dplyr)
sf_use_s2(FALSE)

# Create directory if not exist
ext_dir <- file.path(here(), "inst/extdata")
if(!dir.exists(ext_dir)) dir.create(ext_dir, recursive = TRUE)

## Districts
districts <- st_read(
    here("data-raw/tza_admbnda_adm2_20181019",
         "tza_admbnda_adm2_20181019.shp")) %>%
    mutate(distName = ADM2_EN) %>% select(distName)

st_write(districts, file.path(ext_dir, "districts.geojson"))

# Road
## Need to download OSM data because it is too large
## from https://download.geofabrik.de
roads <- st_read(
    file.path("/Users/pinot/Downloads",
              "tanzania-260111-free.shp", "gis_osm_roads_free_1.shp"))
roads <- roads %>% filter(fclass %in% c("primary", "secondary")) %>%
    mutate(roadid = osm_id) %>% select(roadid)
roads <- st_intersection(roads, districts %>% st_union())

roads <- st_transform(roads, crs = ab_crs)

st_write(roads, file.path(ext_dir, "roads.geojson"))
