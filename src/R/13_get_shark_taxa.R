library(tidyverse)
library(SHARK4R)
library(worrms)

# Find SHARKdata dataset names
datasets <- load_dataset_names("Phytoplankton")
dataset_names <- unique(datasets$dataset_name)

# Load stored file if running from cache
if(file.exists("cache/shark_cache.rda")) {
  load(file = "cache/shark_cache.rda")
} else {
  data <- download_sharkdata(dataset_names)
}

# Update data
data <- update_data(data)

# Find new datasets
missing_datasets <- datasets %>%
  filter(!dataset_name %in% data$dataset_name)

tryCatch({
  data <- bind_rows(data,
                    download_sharkdata(missing_datasets$dataset_name))
  }, error=function(e){
  cat("Failed to download data\n")
  }
)

# Store cached items
save(data, file = "cache/shark_cache.rda")

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Find all taxa not present in NuA database
shark_additions <- data %>%
  select(scientific_name, reported_scientific_name, aphia_id) %>%
  distinct() %>%
  filter(!aphia_id %in% taxa_worms$taxon_id) %>%
  filter(!is.na(aphia_id))

# Skip cached items
aphia_id <- unique(shark_additions$aphia_id)

# Create empty dataframe
all_records <- data.frame()

# Extract records from WoRMS based on AphiaID
if(length(aphia_id) > 0) {
  for(i in 1:length(aphia_id)) {
    record <- wm_record(aphia_id[i])
    
    all_records <- rbind(all_records, record)
    
    cat('Getting record', i, 'of', length(aphia_id),'\n')
  }
}

# Find all taxa that are missing from database
missing_shark_records <- all_records %>%
  filter(!is.na(scientificname)) %>%
  filter(!valid_AphiaID %in% taxa_worms$taxon_id)

# Store file
write_delim(missing_records, "data_out/missing_shark_records.txt", delim = "\t") 