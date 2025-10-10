library(tidyverse)
library(worrms)
library(rgbif)
library(writexl)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Load stored file if running from cache
if(file.exists("cache/synonyms_cache.rda")) {
  load(file = "cache/synonyms_cache.rda")
} else {
  # Get synonyms from WoRMS
  all_synonyms <- data.frame()
}

# Remove cached items
taxa_worms_missing <- taxa_worms %>%
  filter(!taxon_id %in% all_synonyms$valid_AphiaID)

# Loop for each AphiaID
if (nrow(taxa_worms_missing) > 0) {
  for(i in 1:length(taxa_worms_missing$taxon_id)) {
    # Define record and set it to NULL initially
    record <- data.frame(valid_AphiaID = taxa_worms_missing$taxon_id[i])
    cat('Getting synonyms for taxa', i, 'of', length(taxa_worms_missing$taxon_id),'\n')
    tryCatch({record <- wm_synonyms(taxa_worms_missing$taxon_id[i])}, 
             error=function(e){
               cat("Error occurred in AphiaID", taxa_worms_missing$taxon_id[i], ":", conditionMessage(e), "\n")
             })
    all_synonyms <- bind_rows(all_synonyms, record)
    
    save(all_synonyms, file = "cache/synonyms_cache.rda")
  }
}

# Clean names
names_list <- all_synonyms %>%
  filter(!is.na(AphiaID)) %>%
  mutate(name = ifelse(is.na(authority), scientificname,
                       paste(scientificname, authority))) %>%
  mutate(name = iconv(name, from = "", to = "UTF-8")) %>%
  pull(name) %>%
  unique()

# Helper: safe wrapper for a single name
safe_name_lookup <- function(x) {
  tryCatch(
    name_backbone_checklist(x),
    error = function(e) {
      message("Failed: ", x)
      tibble()
    }
  )
}

# Helper: try batch, if it fails → fall back to per-name
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
  split(names_list, ceiling(seq_along(names_list) / 50)), # adjust batch size
  get_gbif_batch
) %>%
  select(usageKey, verbatim_name) %>%
  distinct()

# Get number of occurrences
for (i in 1:nrow(gbif_missing_records)) {
  
  if (!is.na(gbif_missing_records$usageKey[i])) {
    # Call occ_count only if usageKey is not NA
    gbif_missing_records$n_nordic_occurrences[i] <- occ_count(
      taxonKey = gbif_missing_records$usageKey[i], 
      decimalLatitude = '54.6, 70', 
      decimalLongitude = '0, 19.9'
    )
  } else {
    # Set to NA or 0 if usageKey is missing
    gbif_missing_records$n_nordic_occurrences[i] <- NA
  }
  
  # Print progress
  cat('Getting record', i, 'of', nrow(gbif_missing_records), ":",
      gbif_missing_records$scientificName[i], "-",
      gbif_missing_records$n_nordic_occurrences[i], "occurrences", '\n')
}

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  filter(!is.na(AphiaID)) %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)%>%
  mutate(verbatim_name = paste(synonym_name, author)) %>%
  distinct() %>%
  left_join(gbif_missing_records) %>%
  rename(usage_key = usageKey) %>%
  select(-verbatim_name)

# Store file
write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "")
