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
names_df <- all_synonyms %>%
  filter(!is.na(AphiaID)) %>%
  mutate(name = ifelse(is.na(authority), scientificname,
                       paste(scientificname, authority))) %>%
  mutate(name = iconv(name, from = "", to = "UTF-8")) %>%
  select(name, rank) %>%
  mutate(rank = gsub("Forma", "Form", rank)) %>%
  distinct()

# Safe single-name lookup which passes rank when present
safe_name_lookup <- function(name, rank) {
  tryCatch({
    if (is.na(rank) || rank == "") {
      # call without rank if rank missing
      name_backbone_checklist(name = name, strict = FALSE)
    } else {
      # include rank argument
      name_backbone_checklist(name = name, rank = rank, strict = FALSE)
    }
  }, error = function(e) {
    message("Failed: ", name, " (rank: ", rank, ") -> ", conditionMessage(e))
    tibble()  # return empty tibble on error so map_dfr keeps working
  })
}

# Batch wrapper: try vectorized call first (faster), if it errors -> fallback to individual calls with rank
get_gbif_batch <- function(df_chunk) {
  # df_chunk is a tibble with columns name, rank, rowid
  tryCatch({
    # fast attempt: vectorized call with just names (no per-name ranks)
    name_backbone_checklist(name = df_chunk$name, rank = df_chunk$rank, strict = FALSE)
  }, error = function(e) {
    message("Batch failed, retrying individually with rank... (", nrow(df_chunk), " names)")
    # map each name => safe lookup with rank
    map2_dfr(df_chunk$name, df_chunk$rank, safe_name_lookup)
  })
}

# Run in batches of 50 (adjust size as desired)
batch_size <- 50

gbif_missing_records <- names_df %>%
  split(ceiling(seq_len(nrow(names_df)) / batch_size)) %>%
  map_dfr(get_gbif_batch) %>%
  select(usageKey, verbatim_name, matchType, scientificName) %>%
  filter(matchType == "EXACT") %>%
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
  select(-verbatim_name, -matchType, -scientificName)

# Store file
write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "")
