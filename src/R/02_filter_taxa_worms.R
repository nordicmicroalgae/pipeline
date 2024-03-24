library(tidyverse)
library(writexl)

# Source function to extract all parent ids from taxa list
source("src/R/fun/get_all_parents.R")

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/taxa_worms.txt", locale = locale(encoding = "latin1"))

# Read whitelist for forcing the addition of an unaccepted taxa
whitelist <- read_tsv("data_in/whitelist.txt")

# Read blacklist for removing unwanted
blacklist <- read_tsv("data_in/blacklist.txt")

# Remove all unaccepted names that appear when constructing the higher taxonomy
taxa_worms_accepted <- taxa_worms %>%
  filter(!status == "unaccepted" | aphia_id %in% whitelist$taxon_id) %>%
  filter(!is.na(scientific_name)) %>%
  rename(taxon_id = aphia_id) %>%
  filter(!taxon_id %in% blacklist$taxon_id)

# Removing unaccepted taxa will break the tree, find all broken links
broken_tree <- taxa_worms_accepted %>%
  filter(!parent_id %in% taxon_id & !is.na(parent_id))

# Initialize a vector to store the first parent_id for each taxon_id
first_parent_ids <- vector("numeric", length = nrow(broken_tree))
first_parent_names <- vector("character", length = nrow(broken_tree))

# Iterate over each row of broken_tree
for (i in 1:nrow(broken_tree)) {
  # Get all parent_ids for the current taxon_id
  parent_ids <- get_all_parents(broken_tree$taxon_id[i], taxa_worms)
  
  # Find the first parent_id that exists in taxa_worms_accepted$taxon_id
  first_parent <- parent_ids[which(parent_ids %in% taxa_worms_accepted$taxon_id)[1]]
  
  # Get the name corresponding to the first_parent_id
  first_parent_name <- taxa_worms$scientific_name[taxa_worms$aphia_id == first_parent]
  
  # Assign the first parent_id to the vector
  first_parent_ids[i] <- first_parent
  first_parent_names[i] <- first_parent_name
}

# Add the first_parent_ids and first_parent_names vectors as new columns to df
broken_tree$first_parent_id <- first_parent_ids
broken_tree$first_parent_names <- first_parent_names

# Select relevant columns
broken_tree <- broken_tree %>%
  select(taxon_id, first_parent_id, first_parent_names) 

# Redirect tree to the closest accepted taxa
taxa_worms_accepted <- taxa_worms_accepted %>%
  left_join(broken_tree) %>%
  mutate(parent_id = ifelse(is.na(first_parent_id), parent_id, first_parent_id),
         parent_name = ifelse(is.na(first_parent_id), parent_name, first_parent_names)) %>%
  select(-first_parent_id, -first_parent_names)

# Find all unaccepted names that has been removed
taxa_worms_unaccepted <- taxa_worms %>%
  filter(status == "unaccepted") %>%
  rename(taxon_id = aphia_id)

# Find duplicated taxa names
duplicates <- taxa_worms_accepted %>%
  filter(duplicated(scientific_name))

# Create separate file with worms links
worms_links <- taxa_worms_accepted %>%
  mutate(aphia_id = taxon_id) %>%
  select(taxon_id, aphia_id, url)

# Find current date for checklist
date <- format(Sys.Date(),
               "%Y_%b_%d")

# Summarise checklist
checklist <- taxa_worms_accepted %>%
  filter(rank %in% c("Species", "Subspecies", "Variety", "Forma")) %>%
  arrange(scientific_name) %>%
  rename(aphia_id = taxon_id)

# Store files
write_tsv(taxa_worms_unaccepted, "data_out/taxa_worms_unaccepted.txt", na = "") 
write_tsv(taxa_worms_accepted, "data_out/content/taxa.txt", na = "") 
write_tsv(worms_links, "data_out/content/facts_external_links_worms.txt", na = "") 
write_tsv(duplicates, "data_out/duplicated_scientific_name.txt", na = "") 
write_tsv(checklist, paste0("data_out/nordicmicroalgae_checklist_", date, ".txt"), na = "") 
write_xlsx(checklist, paste0("data_out/nordicmicroalgae_checklist_", date, ".xlsx"), format_headers = FALSE)