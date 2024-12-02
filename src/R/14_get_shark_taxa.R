library(tidyverse)
library(SHARK4R)
library(worrms)

# Get SHARK options
shark_options <- get_shark_options()

min_year <- shark_options$minYear
max_year <- shark_options$maxYear
dataset_names <- unlist(shark_options$datasets)[grepl("Phytoplankton", unlist(shark_options$datasets))]

# Load stored file if running from cache
if(file.exists("cache/shark_cache.rda")) {
  load(file = "cache/shark_cache.rda")
} else {
  # data <- download_sharkdata(dataset_names)

  
  data <- get_shark_data(tableView = "sharkdata_phytoplankton",
                         dataTypes = "Phytoplankton",
                         fromYear = min_year,
                         toYear = max_year,
                         verbose = FALSE)
}

# Find missing dataset file names
outdated_datasets <- unique(data$dataset_file_name)[!unique(data$dataset_file_name) %in% dataset_names]

if(length(outdated_datasets) > 0) {
  missing_dataset_names <- dataset_names[grepl(paste0(outdated_datasets, collapse = "|"), dataset_names)]
  
  # Download latest version of data
  data_updated <- get_shark_data(tableView = "sharkdata_phytoplankton",
                                 dataTypes = "Phytoplankton",
                                 fromYear = min_year,
                                 toYear = max_year,
                                 datasets = missing_dataset_names,
                                 verbose = FALSE)
  
  # Replace outdated data
  data <- data %>%
    filter(!dataset_name %in% missing_dataset_names) %>%
    bind_rows(data_updated)
  }

# Find missing datasets
missing_datasets <- dataset_names[!dataset_names %in% data$dataset_file_name]

# Add data if any datasets are missing
if(length(missing_datasets) > 0) {
  tryCatch({
    data <- bind_rows(data,
                      get_shark_data(tableView = "sharkdata_phytoplankton",
                                     dataTypes = "Phytoplankton",
                                     fromYear = min_year,
                                     toYear = max_year,
                                     datasets = missing_datasets,
                                     verbose = FALSE))
  }, error=function(e){
    cat("Failed to download data\n")
  }
  )
}

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
write_delim(missing_shark_records, "data_out/missing_shark_records.txt", delim = "\t") 
