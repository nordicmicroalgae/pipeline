library(tidyverse)

# Read NORCCA taxa lists
norcca <- read_tsv("data_in/norcca_extended.txt") # Full list with links
norcca_worms <- read_tsv("data_in/norcca_extended_taxa_names_matched.txt") # List that has been matched with the WoRMS web match interface
norcca_strains <- read_tsv("data_in/norcca_strains.txt") # List that has been matched with the WoRMS web match interface

# Fix column names and select relevant information
norcca_worms <- norcca_worms %>%
  rename(scientific_name = ScientificName...1,
         ScientificName = ScientificName...4,
         status = `Taxon status`) %>%
  select(scientific_name, status, AphiaID, AphiaID_accepted)

# Read taxa_worms file
taxa_worms <- read_tsv("data_in/taxa_worms.txt")



# Join tables
norcca_combined <- norcca_strains %>%
  mutate(scientific_name = Species) %>%
  left_join(norcca_worms) %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", AphiaID_accepted, AphiaID),
         scientific_name = gsub(" sp.", "", scientific_name)) %>%
  select(-status, -AphiaID, -AphiaID_accepted) %>%
  rename(AphiaID = used_aphia_id) %>%
  filter(AphiaID %in% taxa_worms$aphia_id)



# # Join tables
# norcca_combined <- norcca %>%
#   left_join(norcca_worms) %>%
#   mutate(used_aphia_id = ifelse(status == "unaccepted", AphiaID_accepted, AphiaID),
#          scientific_name = gsub(" sp.", "", scientific_name)) %>%
#   select(-status, -AphiaID, -AphiaID_accepted, -class, -environment) %>%
#   rename(AphiaID = used_aphia_id) %>%
#   filter(AphiaID %in% taxa_worms$aphia_id) %>%
#   rename("Link to NORCCA website" = taxa_link)

# Version with only links to species, not all strains
norcca_short <- norcca_combined %>%
  select(-strain, -strain_link) %>%
  distinct() %>%
  rename("Link to NORCCA website" = taxa_link)
 
# Store file
write_delim(norcca_combined, "data_out/norcca_strains_id.txt", delim = "\t", na = "")
write_delim(norcca_short, "data_out/norcca.txt", delim = "\t") 
