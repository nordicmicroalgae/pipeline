library(tidyverse)
library(worrms)
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
taxa_worms <- taxa_worms %>%
  filter(!taxon_id %in% all_synonyms$valid_AphiaID)

# Loop for each AphiaID
if (nrow(taxa_worms) > 0) {
  for(i in 1:length(taxa_worms$taxon_id)) {
    tryCatch({
      record <- wm_synonyms(taxa_worms$taxon_id[i])
      
      all_synonyms <- rbind(all_synonyms, record)
      
      # Store cached item
      save(all_synonyms, file = "cache/synonyms_cache.rda")
    }, error=function(e){})
    cat('Getting synonyms for taxa', i, 'of', length(taxa_worms$taxon_id),'\n')
  }
}

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Store file
write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "")