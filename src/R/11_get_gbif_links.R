library(rgbif)
library(tidyverse)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols()) %>%
  mutate(scientific_name_authority = paste(scientific_name, authority))

synonyms <- read_tsv("data_out/content/synonyms.txt",
                     col_types = cols())

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
  
  # Prepare a small tibble with the two columns you asked for
  names_df <- taxa_worms %>%
    select(scientific_name_authority, rank) %>%
    distinct() %>%            # optional: avoid duplicate queries
    mutate(rowid = row_number())
  
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
    # df_chunk is a tibble with columns scientific_name_authority, rank, rowid
    tryCatch({
      # fast attempt: vectorized call with just names (no per-name ranks)
      name_backbone_checklist(name = df_chunk$scientific_name_authority, rank = df_chunk$rank, strict = FALSE)
    }, error = function(e) {
      message("Batch failed, retrying individually with rank... (", nrow(df_chunk), " names)")
      # map each name => safe lookup with rank
      map2_dfr(df_chunk$scientific_name_authority, df_chunk$rank, safe_name_lookup)
    })
  }
  
  # Run in batches of 50 (adjust size as desired)
  batch_size <- 50
  gbif_missing_records <- names_df %>%
    split(ceiling(seq_len(nrow(names_df)) / batch_size)) %>%
    map_dfr(get_gbif_batch) %>%
    mutate(usageKey = ifelse(matchType == "HIGHERRANK", NA, usageKey))
  
  # Keep only desired columns
  gbif_missing_records <- gbif_missing_records %>%
    select(usageKey, verbatim_name) %>%
    distinct() %>%
    mutate(n_nordic_occurrences = NA)
  
  # Get number of occurrences
  for (i in 1:nrow(gbif_missing_records)) {
    
    if (is.na(gbif_missing_records$usageKey[i])) {
      cat('Skipping record', i, 'of', nrow(gbif_missing_records), ":", gbif_missing_records$verbatim_name[i],
          "-", gbif_missing_records$usageKey[i], '\n')
      
      gbif_missing_records$n_nordic_occurrences[i] <- NA
      
      next
    }
    
    # From scandinavian records
    gbif_missing_records$n_nordic_occurrences[i] <- occ_count(taxonKey=gbif_missing_records$usageKey[i], 
                                                              decimalLatitude='54.6, 70', 
                                                              decimalLongitude='0, 19.9')
    
    # Print progress
    cat('Getting record', i, 'of', nrow(gbif_missing_records), ":", gbif_missing_records$verbatim_name[i],
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
  select(taxon_id, scientific_name, scientific_name_authority) %>%
  right_join(gbif_records, by = c("scientific_name_authority" = "verbatim_name")) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(usageKey)) %>%
  filter(taxon_id %in% taxa_worms$taxon_id) %>%
  mutate(url = paste0("www.gbif.org/species/", usageKey)) %>%
  select(taxon_id, scientific_name, scientific_name_authority, usageKey, url, n_nordic_occurrences) %>%
  rename(usage_key = usageKey)

# Identify poor matches
problems <- synonyms %>%
  select(-n_nordic_occurrences) %>%
  rename(usage_key_synonym = usage_key) %>%
  left_join(gbif_list) %>%
  filter(usage_key == usage_key_synonym)

# Summarize synonyms
synonyms_summary <- synonyms %>%
  filter(!usage_key %in% problems$usage_key_synonym) %>%
  filter(!is.na(usage_key)) %>%
  # filter(!n_nordic_occurrences == 0) %>%
  group_by(taxon_id) %>%
  summarise(
    synonym_usage_key = paste(na.omit(usage_key), collapse = ", "),
    synonym_names = paste(na.omit(synonym_name), collapse = ", "),
    synonyms_n_nordic_occurrences = sum(n_nordic_occurrences, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    synonym_usage_key = na_if(synonym_usage_key, ""),
    synonym_names = na_if(synonym_names, "")
  ) %>%
  filter(!is.na(synonym_usage_key))

# Join with synonyms add add nordic occurrences
gbif_list <- gbif_list %>%
  left_join(synonyms_summary) %>%
  mutate(synonyms_n_nordic_occurrences = if_else(is.na(synonyms_n_nordic_occurrences), 0, synonyms_n_nordic_occurrences)) %>%
  mutate(n_nordic_occurrences = n_nordic_occurrences + synonyms_n_nordic_occurrences)

# Change between heatmap and points based on number of occurrences
gbif_list <- gbif_list %>%
  mutate(point_style = ifelse(n_nordic_occurrences > 30000, "orangeHeat.point", "scaled.circles"))

# Verify that synonym ids and names are equally long
synonyms_summary_checked <- gbif_list %>%
  mutate(
    n_keys = str_count(synonym_usage_key, ",") + 1,
    n_names = str_count(synonym_names, ",") + 1,
    equal_length = n_keys == n_names
  )

# View rows where counts differ
synonym_check <- synonyms_summary_checked %>%
  filter(!equal_length)

if (nrow(synonym_check) > 0) {
  stop("synonym_names and synonym_usage_key do not match")
}

# Store file
write_delim(gbif_list, "data_out/content/facts_external_links_gbif.txt", delim = "\t", na = "") 
