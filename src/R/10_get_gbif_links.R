library(rgbif)
library(tidyverse)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols()) %>%
  mutate(scientific_name_authority = paste(scientific_name, authority))

# Get GBIF id
# Load stored file if running from cache
if(file.exists("cache/gbif_cache.rda")) {
  load(file = "cache/gbif_cache.rda")
} else {
  gbif_records <- data.frame()
}

# Remove cached items
taxa_worms_missing <- taxa_worms %>%
  filter(!scientific_name_authority %in% gbif_records$verbatim_name)

# Get GBIF records
if (nrow(taxa_worms_missing > 0)) {
  gbif_missing_records <- taxa_worms_missing %>%
    rename(name = scientific_name_authority) %>%
    name_backbone_checklist()
  
  # Bind with cached items
  gbif_records <- rbind(gbif_records,
                        gbif_missing_records)
}

# Store cached items
save(gbif_records, file = "cache/gbif_cache.rda")

# Add taxon_id and filter NA
gbif_list <- taxa_worms %>%
  select(taxon_id, scientific_name_authority) %>%
  right_join(gbif_records, by = c("scientific_name_authority" = "verbatim_name")) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(usageKey)) %>%
  mutate(url = paste0("www.gbif.org/species/", usageKey)) %>%
  select(taxon_id, scientific_name_authority, usageKey, url) %>%
  rename(usage_key = usageKey) %>%
  mutate(n_nordic_occurrences = NA)
  
# Get number of occurrences
for (i in 1:nrow(gbif_list)) {
  # From scandinavian records
  gbif_list$n_nordic_occurrences[i] <- occ_count(taxonKey=gbif_list$usage_key[i], 
                                                 decimalLatitude='54.6, 70', 
                                                 decimalLongitude='0, 19.9')
  
  # Print progress
  cat('Getting record', i, 'of', nrow(gbif_list), ":", gbif_list$scientific_name_authority[i],
      "-", gbif_list$n_nordic_occurrences[i], "occurences", '\n')
}


# Change between heatmap and points based on number of occurrences
gbif_list <- gbif_list %>%
  mutate(point_style = ifelse(n_nordic_occurrences > 30000, "orangeHeat.point", "scaled.circles"))

# Store file
write_delim(gbif_list, "data_out/content/facts_external_links_gbif.txt", delim = "\t") 
