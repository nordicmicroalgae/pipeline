library(tidyverse)
library(writexl)
library(SHARK4R)
library(stringdist)

# Load API key
if(!exists('ALGAEBASE_APIKEY')) {
  ALGAEBASE_APIKEY <- Sys.getenv("ALGAEBASE_APIKEY")
}

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Prepare names for AlgaeBase API query
algaebase_species_api <- taxa_worms %>%
  filter(rank %in% c("Species", "Variety", "Forma", "Subspecies", "Genus")) %>%
  select(scientific_name, authority, rank, taxon_id)

# Parse scientific names
algaebase_species_api <- parse_scientific_names(algaebase_species_api$scientific_name) %>%
  cbind(algaebase_species_api) %>%
  filter(!duplicated(scientific_name)) %>%
  # mutate(species = gsub("^(\\w+) \\1$", "\\1", species)) %>% # To merge duplicated species names, e.g. Achnantes dispar var. dispar
  mutate(input_name = str_trim(paste(genus, species))) %>%
  mutate(species = na_if(species, ""))

# Load stored file if running from cache
if(file.exists("cache/algaebase_cache.rda")) {
  load(file = "cache/algaebase_cache.rda")
} else {
  algaebase_results <- data.frame()
}

# Remove cached items
algaebase_species_api_missing <- algaebase_species_api %>%
  filter(!input_name %in% algaebase_results$input_name)

# Calculate the number of rows once
missing_rows <- nrow(algaebase_species_api_missing)

# If there are missing rows, call the API and update the dataframe
if (missing_rows > 0) {
  # Call the Algaebase API
  api_results <- match_algaebase(genus = algaebase_species_api_missing$genus, 
                                 species = algaebase_species_api_missing$species,
                                 apikey = ALGAEBASE_APIKEY,
                                 newest_only = FALSE,
                                 verbose = TRUE)
  
  # Append the API results to the main dataframe
  algaebase_results <- rbind(algaebase_results, api_results)
}

# Find taxon_id that did not get a match
no_match <- algaebase_species_api_missing %>%
  filter(!algaebase_species_api_missing$input_name %in% algaebase_results$input_name) %>%
  select(input_name)

# Add taxon_id for results that did not get a match
algaebase_results <- bind_rows(algaebase_results, no_match)

# Save cache
save(algaebase_results, file = "cache/algaebase_cache.rda")

# Join and wrangle
algaebase_results <- algaebase_results %>% 
  distinct() %>%
  left_join(select(algaebase_species_api, 
                   -genus,
                   -species)
            , by = 'input_name') %>%
  mutate(url = ifelse(taxon_rank=="genus",
                      paste0("https://www.algaebase.org/search/genus/detail/?genus_id=", id),
                      paste0("https://www.algaebase.org/search/species/detail/?species_id=", id)
  )
  ) %>%
  select(taxon_id, id, scientific_name, authority, rank, kingdom, phylum, class, order, family, genus, species, taxon_rank, authorship, currently_accepted, nomenclatural_status, url) %>%
  rename(ab_id = id) %>%
  filter(!is.na(ab_id)) %>%
  filter(!is.na(taxon_id)) %>%
  distinct(taxon_id, ab_id, .keep_all = TRUE) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Identify and solve duplicated matches by authority and taxonomic status
duplicates <- algaebase_results %>%
  filter(taxon_id %in% taxon_id[duplicated(taxon_id)]) %>%
  group_by(taxon_id) %>%
  filter(tolower(rank) == taxon_rank) %>%
  mutate(
    authority_clean = str_remove_all(authority, "[[:punct:]]") %>% str_squish(),
    authorship_clean = str_remove_all(authorship, "[[:punct:]]") %>% str_squish()
  ) %>%
  filter(str_detect(authority_clean, fixed(authorship_clean, ignore_case = TRUE)) |
           str_detect(authorship_clean, fixed(authority_clean, ignore_case = TRUE)) | n() == 1) %>%
  filter(
    (n() > 1 & is.na(nomenclatural_status) | nomenclatural_status != "nom. illeg.") | n() == 1
  ) %>%
  filter(
    (n() > 1 & currently_accepted == 1) | n() == 1 # Keep accepted or non-duplicated rows
  ) %>%
  ungroup()

# Identify duplicates that could not be resolved in previous step
duplicates_left <- algaebase_results %>%
  filter(taxon_id %in% taxon_id[duplicated(taxon_id)]) %>%
  filter(!taxon_id %in% duplicates$taxon_id) %>%
  mutate(
    authority_clean = gsub("\\b[A-Z]\\.", "", authority) %>% str_squish(),
    authorship_clean = gsub("\\b[A-Z]\\.", "", authorship) %>% str_squish()
  ) %>%
  mutate(
    authority_clean = str_remove_all(authority_clean, "[[:punct:]]") %>% str_squish(),
    authorship_clean = str_remove_all(authorship_clean, "[[:punct:]]") %>% str_squish()
  ) %>%
  mutate(
    authority_clean =  gsub("\\b\\d{4}\\b", "", authority_clean) %>% str_squish()
  )

# Find matches using a fuzzy search tool
fuzzy_matches <- duplicates_left %>%
  rowwise() %>%
  mutate(
    string_distance = stringdist(authority_clean, authorship_clean, method = "lv"), # Levenshtein distance
    match = string_distance <= 3 # Allow up to 3 mismatches
  ) %>%
  filter(match) %>%
  ungroup() %>%
  select(-string_distance, -match)

# Bind the solved duplicates
duplicates_cleaned <- rbind(duplicates, fuzzy_matches) %>%
  select(-authority_clean, -authorship_clean)

# Bind the results with solved duplicates
algaebase_results <- algaebase_results %>%
  filter(!taxon_id %in% duplicates_cleaned$taxon_id) %>%
  rbind(duplicates_cleaned)

# Identify any remaining duplicates and solve by nomenclatural status
dups<-algaebase_results %>%
  filter(taxon_id %in% taxon_id[duplicated(taxon_id)]) %>%
  filter(is.na(nomenclatural_status))

# Bind the results with solved duplicates
algaebase_results <- algaebase_results %>%
  filter(!taxon_id %in% dups$taxon_id) %>%
  rbind(dups)

# Identify remaining duplicates
algaebase_duplicates <- algaebase_results %>%
  filter(taxon_id %in% taxon_id[duplicated(taxon_id)])

# Identify taxa that lack AlgaeBase links
algaebase_missing <- taxa_worms %>%
  filter(!taxon_id %in% algaebase_results$taxon_id) %>%
  filter(rank %in% c("Species", "Variety", "Genus", "Forma", "Subspecies"))

# Store files
write_tsv(algaebase_results, "data_out/content/facts_external_links_algaebase.txt", na = "")
write_tsv(algaebase_duplicates, "data_out/algaebase_duplicates.txt", na = "")
write_tsv(algaebase_missing, "data_out/algaebase_missing_taxa.txt", na = "")

