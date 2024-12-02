library(tidyverse)
library(SHARK4R)

if(!exists('subscription_key')) {
  subscription_key <- Sys.getenv("DYNTAXA_APIKEY")
}

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Load stored file if running from cache
if(file.exists("cache/dyntaxa_cache.rda")) {
  load(file = "cache/dyntaxa_cache.rda")
} else {
  dyntaxa <- data.frame() 
}

taxa_worms_missing <- taxa_worms %>%
  filter(!scientific_name %in% dyntaxa$search_pattern)

# Match taxa with API
dyntaxa <- rbind(match_taxon_name(taxa_worms_missing$scientific_name, subscription_key, verbose = FALSE),
                 dyntaxa)

save(dyntaxa, file = "cache/dyntaxa_cache.rda")

# Match taxa_worms with Dyntaxa through the web match interface, read .txt-file here
dyntaxa_records <- read.table("data_in/dyntaxa_match.txt", 
                              header=TRUE, 
                              sep="\t", 
                              fill = TRUE, 
                              encoding = "latin1",
                              quote = "")

# Select the manually selected taxa
dyntaxa_matched <- dyntaxa_records %>%
  filter(Matchstatus == "Manuellt val") %>%
  select(Sökterm, Taxon.id) %>%
  rename(search_pattern = Sökterm)

# Gather taxa information
taxa <- taxa_worms %>%
  select(scientific_name, taxon_id)

# Combine API results with manually selected ids
dyntaxa_list <- dyntaxa %>%
  filter(!is.na(taxon_id)) %>%
  distinct() %>%
  left_join(dyntaxa_matched) %>%
  mutate(taxon_id = ifelse(is.na(Taxon.id) | taxon_id == Taxon.id, taxon_id, Taxon.id)) %>%
  select(-Taxon.id, -best_match) %>%
  rename(dyntaxa_id = taxon_id,
         scientific_name = search_pattern) %>%
  left_join(taxa) %>%
  filter(taxon_id %in% taxa_worms$taxon_id)

# Store file
write_delim(dyntaxa_list, "data_out/content/facts_external_links_dyntaxa.txt", delim = "\t") 