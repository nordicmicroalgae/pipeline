library(tidyverse)
library(worrms)
library(rgbif)
library(writexl)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Load stored file if running from cache
if(file.exists("cache/synonyms_cache.rda")) {
  load(file = "cache/synonyms_cache.rda")
} else {
  # Get synonyms from WoRMS
  all_synonyms <- data.frame()
}

# Remove cached items
taxa_worms_missing <- taxa_worms %>%
  filter(!taxon_id %in% all_synonyms$valid_AphiaID)

# Loop for each AphiaID
if (nrow(taxa_worms_missing) > 0) {
  for(i in 1:length(taxa_worms_missing$taxon_id)) {
    # Define record and set it to NULL initially
    record <- data.frame(valid_AphiaID = taxa_worms_missing$taxon_id[i])
    cat('Getting synonyms for taxa', i, 'of', length(taxa_worms_missing$taxon_id),'\n')
    tryCatch({record <- wm_synonyms(taxa_worms_missing$taxon_id[i])}, 
             error=function(e){
               cat("Error occurred in AphiaID", taxa_worms_missing$taxon_id[i], ":", conditionMessage(e), "\n")
             })
    all_synonyms <- bind_rows(all_synonyms, record)
    
    save(all_synonyms, file = "cache/synonyms_cache.rda")
  }
}

# Get GBIF ids for API call
gbif_missing_records <- all_synonyms %>%
  filter(!is.na(AphiaID)) %>%
  mutate(name = paste(scientificname, authority)) %>%
  name_backbone_checklist() %>%
  select(usageKey, verbatim_name) %>%
  distinct()

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  filter(!is.na(AphiaID)) %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)%>%
  mutate(verbatim_name = paste(synonym_name, author)) %>%
  distinct() %>%
  left_join(gbif_missing_records) %>%
  rename(usage_key = usageKey) %>%
  select(-verbatim_name)

# Store file
write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "")
