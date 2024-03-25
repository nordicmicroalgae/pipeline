library(tidyverse)
library(writexl)
library(algaeClassify)

# Source modified functions from the algaeClassify package
source("src/R/fun/algaebase_genus_search.r") # Edited function from algaeClassify, with added id
source("src/R/fun/algaebase_species_search.r") # Edited function from algaeClassify, with added id
source("src/R/fun/algaebase_search_df.r") # Edited function from algaeClassify, with added id

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

# # Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
# algaebase_species <- taxa_worms %>%
#   filter(rank %in% c("Species", "Variety", "Forma", "Subspecies")) %>%
#   mutate(scientific_name_author = paste(scientific_name, authority)) %>%
#   select(scientific_name_author, rank, taxon_id)
# 
# # Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
# algaebase_genus <- taxa_worms %>%
#   filter(rank == "Genus") %>%
#   mutate(scientific_name_author = paste(scientific_name, authority)) %>%
#   select(scientific_name_author, rank, taxon_id)
# 
# # Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
# algaebase_higher_taxonomy <- taxa_worms %>%
#   filter(!rank %in% c("Species", "Variety", "Forma", "Subspecies", "Genus")) %>%
#   mutate(scientific_name_author = paste(scientific_name, authority)) %>%
#   select(scientific_name_author, rank, taxon_id)
# 
# # Store files as .xlsx
# write_xlsx(algaebase_species, "data_out/nordic_microalgae_species.xlsx")
# write_xlsx(algaebase_genus, "data_out/nordic_microalgae_genus.xlsx")
# write_xlsx(algaebase_higher_taxonomy, "data_out/nordic_microalgae_higher_taxonomy.xlsx")

# Prepare names for AlgaeBase API query
algaebase_species_api <- taxa_worms %>%
  filter(rank %in% c("Species", "Variety", "Forma", "Subspecies", "Genus")) %>%
  select(scientific_name, rank, taxon_id) %>%
  genus_species_extract(phyto.name = 'scientific_name') %>%
  filter(!duplicated(scientific_name)) %>%
  mutate(input.name = str_trim(paste(genus, species))) %>%
  mutate(species = na_if(species, ""))

# Load stored file if running from cache
if(file.exists("cache/algaebase_cache.rda")) {
  load(file = "cache/algaebase_cache.rda")
} else {
  algaebase_results <- data.frame()
}

# Remove cached items
algaebase_species_api_missing <- algaebase_species_api %>%
  filter(!input.name %in% algaebase_results$input.name)

# Calculate the number of rows once
missing_rows <- nrow(algaebase_species_api_missing)

# If there are missing rows, call the API and update the dataframe
if (missing_rows > 0) {
  # Call the Algaebase API
  api_results <- algaebase_search_df(algaebase_species_api_missing, 
                                     apikey = ALGAEBASE_APIKEY,
                                     genus.name = "genus",
                                     species.name = "species")
  
  # Append the API results to the main dataframe
  algaebase_results <- rbind(algaebase_results, api_results)
}

# Find taxon_id that did not get a match
no_match <- algaebase_species_api_missing %>%
  filter(!algaebase_species_api_missing$input.name %in% algaebase_results$input.name) %>%
  select(input.name)

# Add taxon_id for results that did not get a match
algaebase_results <- bind_rows(algaebase_results, no_match)

# Save cache
save(algaebase_results, file = "cache/algaebase_cache.rda")

# Join and wrangle
algaebase_results <- algaebase_results %>% 
  # rename(scientific_name = input.name) %>%
  distinct() %>%
  left_join(select(algaebase_species_api, 
                   -genus,
                   -species)
            , by = 'input.name') %>%
  mutate(url = ifelse(taxon.rank=="genus",
                      paste0("https://www.algaebase.org/search/genus/detail/?genus_id=", id),
                      paste0("https://www.algaebase.org/search/species/detail/?species_id=", id)
  )
  ) %>%
  select(taxon_id, id, scientific_name, kingdom, phylum, class, order, family, genus, species, taxon.rank, url) %>%
  rename(ab_id = id,
         taxon_rank = taxon.rank) %>%
  filter(!is.na(ab_id)) %>%
  filter(!is.na(taxon_id)) %>%
  distinct(taxon_id, ab_id, .keep_all = TRUE) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Store file
write_tsv(algaebase_results, "data_out/content/facts_external_links_algaebase.txt", na = "")
