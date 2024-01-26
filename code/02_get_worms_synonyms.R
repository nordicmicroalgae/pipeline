library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_in/taxa_worms.txt")

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
  select(provider, scientificname, valid_AphiaID) %>%
  rename(synonym_name = scientificname,
         AphiaID = valid_AphiaID)

# Store file
write_delim(worms_synonyms, "data_out/worms_synonyms.txt", delim = "\t") 

# Remove all unaccepted names that appear when constructing the higher taxonomy
taxa_worms_accepted <- taxa_worms %>%
  filter(!status == "unaccepted")

# Store file
write_delim(taxa_worms_accepted, "data_out/taxa_worms_accepted.txt", delim = "\t") 