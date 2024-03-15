library(rgbif)
library(tidyverse)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols()) %>%
  mutate(scientific_name_authority = paste(scientific_name, authority))

# Get GBIF id
# Load stored file if running from cache
if(file.exists("cache/gbif_cache.rda")) {
  load(file = "cache/gbif_cache.rda")
} else {
  gbif_records <- taxa_worms %>%
    rename(name = scientific_name_authority) %>%
    name_backbone_checklist()
  
  save(gbif_records, file = "cache/gbif_cache.rda")
}

# Add taxon_id and filter NA
gbif_list <- taxa_worms %>%
  select(taxon_id, scientific_name_authority) %>%
  right_join(gbif_records, by = c("scientific_name_authority" = "verbatim_name")) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(usageKey)) %>%
  mutate(url = paste0("www.gbif.org/species/", usageKey)) %>%
  select(taxon_id, scientific_name_authority, usageKey, url) %>%
  rename(usage_key = usageKey)
  
# Store file
write_delim(gbif_list, "data_out/content/facts_external_links_gbif.txt", delim = "\t") 
