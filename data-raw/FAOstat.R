## code to prepare `FAOstat` dataset
# Load libraries
library(here)
library(dplyr)

# Create directory if not exist
ext_dir <- file.path(here(), "inst/extdata")
if(!dir.exists(ext_dir)) dir.create(ext_dir, recursive = TRUE)

# Load the data
dat <- read.csv(here("data-raw/FAOSTAT_data_en_1-12-2026.csv"))

# Split data into crop types
items <- unique(dat$Item)

for (item in items){
    # Subset the data
    dat_sub <- dat %>% filter(Item == item)

    # Save out to extdata directory
    dat_nm <- tolower(item)
    if (dat_nm == "maize (corn)") dat_nm <- "maize"
    write.csv(dat_sub, file.path(ext_dir, sprintf("FAOSTAT_%s.csv", dat_nm)),
              row.names = FALSE)
}
