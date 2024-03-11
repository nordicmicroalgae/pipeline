library(tidyverse)
library(worrms)
library(writexl)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/taxa_worms.txt", locale = locale(encoding = "latin1"))

# Read whitelist for forcing the addition of an unaccepted taxa
whitelist <- read_tsv("data_in/whitelist.txt")

# Read blacklist for removing unwanted
blacklist <- read_tsv("data_in/blacklist.txt")

# Get synonyms from WoRMS
all_synonyms <- data.frame()

# Load stored file if running from cache
if(file.exists("synonyms_cache.rda")) {
  load(file = "synonyms_cache.rda")
} else {
  # Loop for each AphiaID
  for(i in 1:length(taxa_worms$aphia_id)) {
    tryCatch({
      record <- wm_synonyms(taxa_worms$aphia_id[i])
      
      all_synonyms <- rbind(all_synonyms, record)
    }, error=function(e){})
    cat('Getting synonyms for taxa', i, 'of', length(taxa_worms$aphia_id),'\n')
  }
  save(all_synonyms, file = "synonyms_cache.rda")
}

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID)

# Remove all unaccepted names that appear when constructing the higher taxonomy
taxa_worms_accepted <- taxa_worms %>%
  filter(!status == "unaccepted" | aphia_id %in% whitelist$taxon_id) %>%
  filter(!is.na(scientific_name)) %>%
  rename(taxon_id = aphia_id) %>%
  filter(!taxon_id %in% blacklist$taxon_id)

# Remove all unaccepted names that appear when constructing the higher taxonomy
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
write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "") 
write_tsv(taxa_worms_unaccepted, "data_out/taxa_worms_unaccepted.txt", na = "") 
write_tsv(taxa_worms_accepted, "data_out/content/taxa.txt", na = "") 
write_tsv(worms_links, "data_out/content/facts_external_links_worms.txt", na = "") 
write_tsv(duplicates, "data_out/duplicated_scientific_name.txt", na = "") 
write_tsv(checklist, paste0("data_out/nordicmicroalgae_checklist_", date, ".txt"), na = "") 
write_xlsx(checklist, paste0("data_out/nordicmicroalgae_checklist_", date, ".xlsx"), format_headers = FALSE)