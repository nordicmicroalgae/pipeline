library(tidyverse)
library(writexl)
library(SHARK4R)

# Load API key
if(!exists('ALGAEBASE_APIKEY')) {
  ALGAEBASE_APIKEY <- Sys.getenv("ALGAEBASE_APIKEY")
}

# Read taxa_worms file
taxa_worms <- read.table("data_out/content/taxa.txt", 
                         header=TRUE, 
                         sep="\t", 
                         fill = TRUE, 
                         quote = "", 
                         encoding = "latin-1")

# Prepare names for AlgaeBase API query
algaebase_species_api <- taxa_worms %>%
  filter(rank %in% c("Species", "Variety", "Forma", "Subspecies", "Genus")) %>%
  select(scientific_name, rank, taxon_id)

algaebase_species_api <- parse_scientific_names(algaebase_species_api$scientific_name) %>%
  cbind(algaebase_species_api) %>%
  filter(!duplicated(scientific_name)) %>%
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
  # rename(scientific_name = input_name) %>%
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
  select(taxon_id, id, scientific_name, kingdom, phylum, class, order, family, genus, species, taxon_rank, url) %>%
  rename(ab_id = id) %>%
  filter(!is.na(ab_id)) %>%
  filter(!is.na(taxon_id)) %>%
  distinct(taxon_id, ab_id, .keep_all = TRUE) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Store file
write_tsv(algaebase_results, "data_out/content/facts_external_links_algaebase.txt", na = "")
