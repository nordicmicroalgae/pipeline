library(jsonlite)
library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Read JSON data from a .txt file
json_data <- fromJSON("data_in/ioc-toxins.txt")

# # Parse JSON data into R
# parsed_data <- fromJSON(json_data)

# Convert to tibble
toxins <- json_data$toxins %>%
  as_tibble()

# Filter toxins with known taxa
algal_toxins <- toxins %>%
  filter(lengths(algal_species) > 0)

# Unnest the list column
unnested_tibble <- algal_toxins %>%
  unnest_wider(algal_species, names_sep = "_")

# Create empty data frame
toxin_all <- data.frame()

# Loop for each toxin
for (i in 1:nrow(algal_toxins)) {
  data_ix <- unnested_tibble$algal_species_taxon[[i]] %>%
    mutate(id = algal_toxins$id[i],
           toxin_group = algal_toxins$toxin_group[i],
           recommended_name = algal_toxins$recommended_name[i],
           recommended_acronym = algal_toxins$recommended_acronym[i])
  
  toxin_all <- rbind(toxin_all, data_ix)
}

# Convert aphia_id to numeric
toxin_all$aphia_id <- as.numeric(toxin_all$aphia_id)

# Get all aphia_id
aphia_id <- unique(toxin_all$aphia_id)

# Extract records from WoRMS based on AphiaID
toxin_records <- data.frame()

# Loop for each AphiaID to get current taxonomic records
for(i in 1:length(aphia_id)) {
  tryCatch({
    record <- wm_record(aphia_id[i])
    
    toxin_records <- rbind(toxin_records, record)
    
    cat('Getting record', i, 'of', length(aphia_id),'\n')
  }, error=function(e){
    cat("Error occurred in AphiaID", aphia_id[i], ":", conditionMessage(e), "\n")
  })
}

# Update AphiaID if id is unaccepted and wrangle data
toxin_all_updated <- toxin_records %>%
  select(AphiaID, valid_AphiaID, status) %>%
  rename(aphia_id = AphiaID) %>%
  right_join(toxin_all, by = "aphia_id") %>%
  mutate(taxon_id = ifelse(status == "unaccepted", valid_AphiaID, aphia_id)) %>%
  mutate(taxon_id = ifelse(status == "deleted", valid_AphiaID, aphia_id)) %>%
  select(-valid_AphiaID, -status, -taxon_rank, -LSID, -aphia_id, -accepted_aphia_id) %>%
  relocate(taxon_id) %>%
  mutate(recommended_acronym = coalesce(recommended_acronym, recommended_name),
         url = paste0("https://toxins.hais.ioc-unesco.org/toxins/", id, "/")) %>%
  arrange(scientific_name, recommended_acronym) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Print output
print(paste(length(unique(toxin_all_updated$recommended_name)),
            "IOC toxins found in", 
            length(unique(toxin_all_updated$taxon_id)),
            "taxa in database"))

# Store files
write_tsv(toxin_all_updated, "data_out/content/facts_ioc_toxins.txt") 
