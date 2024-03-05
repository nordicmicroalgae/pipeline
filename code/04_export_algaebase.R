library(tidyverse)
library(writexl)
library(algaeClassify)

# Source modified functions from the algaeClassify package
source("code/fun/algaebase_genus_search.r") # Edited function from algaeClassify, with added id
source("code/fun/algaebase_species_search.r") # Edited function from algaeClassify, with added id
source("code/fun/algaebase_search_df.r") # Edited function from algaeClassify, with added id

# Load API key
if(!exists('ALGAEBASE_APIKEY')) {
  source("code/algaebase_subscription_key.R")
}

# Read taxa_worms file
taxa_worms <- read.table("data_out/content/taxa.txt", 
                         header=TRUE, 
                         sep="\t", 
                         fill = TRUE, 
                         quote = "", 
                         encoding = "latin-1")

# Verify taxa_worms matches so that nothing unexpected appear
unique(taxa_worms$kingdom)

# Verify taxa_worms matches so that nothing unexpected appear
Protozoa <- taxa_worms %>%
  filter(kingdom == "Protozoa")

# Verify taxa_worms matches so that nothing unexpected appear
Animalia <- taxa_worms %>%
  filter(kingdom == "Animalia")

# Verify taxa_worms matches so that nothing unexpected appear
Fungi <- taxa_worms %>%
  filter(kingdom == "Fungi")

# Verify taxa_worms matches so that nothing unexpected appear
Plantae <- taxa_worms %>%
  filter(kingdom == "Plantae")

# Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
algaebase_species <- taxa_worms %>%
  filter(rank %in% c("Species", "Variety", "Forma", "Subspecies")) %>%
  mutate(scientific_name_author = paste(scientific_name, authority)) %>%
  select(scientific_name_author, rank, taxon_id)

# Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
algaebase_genus <- taxa_worms %>%
  filter(rank == "Genus") %>%
  mutate(scientific_name_author = paste(scientific_name, authority)) %>%
  select(scientific_name_author, rank, taxon_id)

# Wrangle data to match AlgaeBase API query, according to Mike Guiry's instructions
algaebase_higher_taxonomy <- taxa_worms %>%
  filter(!rank %in% c("Species", "Variety", "Forma", "Subspecies", "Genus")) %>%
  mutate(scientific_name_author = paste(scientific_name, authority)) %>%
  select(scientific_name_author, rank, taxon_id)

# Store files as .xlsx
write_xlsx(algaebase_species, "data_out/nordic_microalgae_species.xlsx")
write_xlsx(algaebase_genus, "data_out/nordic_microalgae_genus.xlsx")
write_xlsx(algaebase_higher_taxonomy, "data_out/nordic_microalgae_higher_taxonomy.xlsx")

# Prepare names for AlgaeBase API query
algaebase_species_api <- taxa_worms %>%
  filter(rank %in% c("Species", "Variety", "Forma", "Subspecies")) %>%
  select(scientific_name, rank, taxon_id) %>%
  genus_species_extract(phyto.name = 'scientific_name')

# Call the Algaebase API and add taxon_id
algaebase_results <- algaebase_search_df(algaebase_species_api, 
                                         apikey = ALGAEBASE_APIKEY,
                                         genus.name = "genus",
                                         species.name = "species") %>% 
  left_join(algaebase_species_api) %>%
  mutate(url = ifelse(taxon.rank=="genus",
                      paste0("https://www.algaebase.org/search/genus/detail/?genus_id=", id),
                      paste0("https://www.algaebase.org/search/species/detail/?species_id=", id)
                      )
         ) %>%
  select(taxon_id, id, scientific_name, input.name, kingdom, phylum, class, order, family, genus, species, taxon.rank, url) %>%
  rename(input_name = input.name,
         ab_id = id,
         taxon_rank = taxon.rank) %>%
  filter(!is.na(ab_id))

# Store file
write_tsv(algaebase_results, "data_out/content/facts_external_links_algaebase.txt", na = "")
