library(tidyverse)
library(worrms)
library(writexl)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Get synonyms from WoRMS
all_synonyms <- data.frame()

# Load stored file if running from cache
if(file.exists("cache/synonyms_cache.rda")) {
  load(file = "cache/synonyms_cache.rda")
} else {
  # Loop for each AphiaID
  for(i in 1:length(taxa_worms$taxon_id)) {
    tryCatch({
      record <- wm_synonyms(taxa_worms$taxon_id[i])
      
      all_synonyms <- rbind(all_synonyms, record)
    }, error=function(e){})
    cat('Getting synonyms for taxa', i, 'of', length(taxa_worms$taxon_id),'\n')
  }
  save(all_synonyms, file = "cache/synonyms_cache.rda")
}

# Wrangle synonyms
worms_synonyms <- all_synonyms %>%
  mutate(provider = "worms") %>%
  select(provider, scientificname, authority, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         author = authority,
         taxon_id = valid_AphiaID) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

write_tsv(worms_synonyms, "data_out/content/synonyms.txt", na = "") 
