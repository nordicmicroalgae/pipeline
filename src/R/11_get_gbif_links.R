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

  # Extract vector of names
  names_list <- taxa_worms_missing %>%
    pull(scientific_name_authority)
  
  # Safe wrapper for single name
  safe_name_lookup <- function(x) {
    tryCatch(
      name_backbone_checklist(x),
      error = function(e) {
        message("Failed: ", x)
        tibble()
      }
    )
  }
  
  # Batch wrapper
  get_gbif_batch <- function(x) {
    tryCatch(
      name_backbone_checklist(x),
      error = function(e) {
        message("Batch failed, retrying individually...")
        map_dfr(x, safe_name_lookup)
      }
    )
  }
  
  # Run in batches
  gbif_missing_records <- map_dfr(
    split(names_list, ceiling(seq_along(names_list) / 50)),
    get_gbif_batch
  ) 
  
  # Keep only desired columns
  gbif_missing_records <- gbif_missing_records %>%
    select(usageKey, verbatim_name) %>%
    distinct() %>%
    mutate(n_nordic_occurrences = NA)
  
  # Get number of occurrences
  for (i in 1:nrow(gbif_missing_records)) {
    # From scandinavian records
    gbif_missing_records$n_nordic_occurrences[i] <- occ_count(taxonKey=gbif_missing_records$usageKey[i], 
                                                      decimalLatitude='54.6, 70', 
                                                      decimalLongitude='0, 19.9')
    
    # Print progress
    cat('Getting record', i, 'of', nrow(gbif_missing_records), ":", gbif_missing_records$scientificName[i],
        "-", gbif_missing_records$n_nordic_occurrences[i], "occurences", '\n')
  }
  
  # Bind with cached items
  gbif_records <- bind_rows(gbif_records,
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
  filter(taxon_id %in% taxa_worms$taxon_id) %>%
  mutate(url = paste0("www.gbif.org/species/", usageKey)) %>%
  select(taxon_id, scientific_name_authority, usageKey, url, n_nordic_occurrences) %>%
  rename(usage_key = usageKey)

# Change between heatmap and points based on number of occurrences
gbif_list <- gbif_list %>%
  mutate(point_style = ifelse(n_nordic_occurrences > 30000, "orangeHeat.point", "scaled.circles"))

# Store file
write_delim(gbif_list, "data_out/content/facts_external_links_gbif.txt", delim = "\t") 
