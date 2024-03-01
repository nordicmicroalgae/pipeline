library(tidyverse)
library(worrms)
library(writexl)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/taxa_worms.txt", locale = locale(encoding = "latin1"))

# Get synonyms from WoRMS
all_synonyms <- data.frame()

for(i in 1:length(taxa_worms$aphia_id)) {
  tryCatch({
    record <- wm_synonyms(taxa_worms$aphia_id[i])
    
    all_synonyms <- rbind(all_synonyms, record)
  }, error=function(e){})
  cat('Getting synonyms for taxa', i, 'of', length(taxa_worms$aphia_id),'\n')
}

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID)

# Store file
write_delim(worms_synonyms, "data_out/content/synonyms.txt", delim = "\t", na = "") 

# Remove all unaccepted names that appear when constructing the higher taxonomy
taxa_worms_accepted <- taxa_worms %>%
  filter(!status == "unaccepted") %>%
  rename(taxon_id = aphia_id)

# Create separate file with worms links
worms_links <- taxa_worms_accepted %>%
  select(taxon_id, url)

# Find current date for checklist
date <- format(Sys.Date(),
               "%Y_%b_%d")

# Store file
write_tsv(taxa_worms_accepted, "data_out/content/taxa.txt", na = "") 
write_tsv(worms_links, "data_out/content/facts_external_links_worms.txt", na = "") 
write_xlsx(taxa_worms_accepted, paste0("data_out/nordicmicroalgae_checklist_", date, ".xlsx"), format_headers = FALSE)
write_delim(taxa_worms_accepted, paste0("data_out/nordicmicroalgae_checklist_", date, ".txt"), delim = "\t", na = "") 
