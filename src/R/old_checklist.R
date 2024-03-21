library(tidyverse)
library(worrms)
library(jsonlite)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Read taxa_worms file
checklist <- read_tsv("data_in/checklist_of_phytoplankton_in_the_skagerrak-kattegat.txt",
                       col_types = cols(),
                      locale = locale(encoding = "latin1"))

checklist_name <- checklist %>% 
  mutate(scientific_name = gsub("cf[.] ", "", Taxa)) %>%
  mutate(scientific_name = gsub(" sp[.]", "", scientific_name)) %>%
  select(-Hyperlink)

# Store file
write_tsv(checklist_name, "data_out/checklist.txt", na = "")


# Read taxa_worms file
checklist_matched <- read_tsv("data_in/checklist_matched.txt",
                      col_types = cols(),
                      locale = locale(encoding = "UTF-8"))


missing <- checklist_matched %>%
  mutate(taxon_id = ifelse(`Taxon status` == "unaccepted", AphiaID_accepted, AphiaID)) %>%
  mutate(taxon_id = ifelse(`Taxon status` == "deleted", AphiaID_accepted, taxon_id)) %>%
  filter(!taxon_id %in% taxa_worms$taxon_id)

library <- fromJSON("data_in/response_1710766944551.json")

taxa <- library[["media"]][["related_taxon"]]


checklist_matched_name <- checklist_matched %>%
  mutate(scientific_name = ifelse(`Taxon status` == "unaccepted", ScientificName_accepted, ScientificName)) %>%
  mutate(scientific_name = ifelse(`Taxon status` == "deleted", ScientificName_accepted, scientific_name)) %>%
  mutate(taxon_id = ifelse(`Taxon status` == "unaccepted", AphiaID_accepted, AphiaID)) %>%
  mutate(taxon_id = ifelse(`Taxon status` == "deleted", AphiaID_accepted, taxon_id)) %>%
  filter(!scientific_name %in% taxa$scientific_name) %>%
  mutate(in_db = ifelse(taxon_id %in% taxa_worms$taxon_id, "y", "n")) %>%
  rename(checklist_name = Taxa)

# Store file
write_tsv(checklist_matched_name, "data_out/kuylenstierna_missing_images.txt", na = "")
