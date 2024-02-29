library(tidyverse)
library(writexl)

# Read taxa_worms file
taxa_worms <- read.table("data_out/content/taxa.txt", header=TRUE, sep="\t", fill = TRUE, quote = "", encoding = "latin-1")

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
