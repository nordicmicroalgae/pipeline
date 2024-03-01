library(tidyverse)

# Read NORCCA taxa lists
norcca_worms <- read_tsv("data_in/norcca_extended_taxa_names_matched.txt") # List that has been matched with the WoRMS web match interface
norcca_strains <- read_tsv("data_in/norcca_strains.txt") # List that has been matched with the WoRMS web match interface
taxa_worms <- read_tsv("data_out/content/taxa.txt")

# Fix column names and select relevant information
norcca_worms <- norcca_worms %>%
  rename(scientific_name = ScientificName...1,
         ScientificName = ScientificName...4,
         status = `Taxon status`) %>%
  select(scientific_name, status, AphiaID, AphiaID_accepted)

# Join tables
norcca_combined <- norcca_strains %>%
  mutate(scientific_name = Species) %>%
  left_join(norcca_worms) %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", AphiaID_accepted, AphiaID),
         scientific_name = gsub(" sp.", "", scientific_name)) %>%
  select(-status, -AphiaID, -AphiaID_accepted) %>%
  rename(taxon_id = used_aphia_id) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Store file
write_tsv(norcca_combined, "data_out/content/facts_external_links_norcca.txt", na = "")