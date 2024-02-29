library(tidyverse)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt")

# Match taxa_worms with Dyntaxa through the web match interface, read .txt-file here
dyntaxa_records <- read.table("data_in/dyntaxa_match.txt", 
                              header=TRUE, 
                              sep="\t", 
                              fill = TRUE, 
                              encoding = "latin1",
                              quote = "")

# Remove the multiple choice that could not be solved and wrangle data
dyntaxa_list <- dyntaxa_records %>%
  filter(!Matchstatus == "Manuellt val måste göras") %>%
  select(Sökterm, Taxon.id) %>%
  filter(!is.na(Taxon.id)) %>%
  rename(scientific_name = Sökterm,
         dyntaxa_id = Taxon.id) %>%
  distinct()

# Join with taxa_worms
dyntaxa_list <- taxa_worms %>%
  select(taxon_id, scientific_name) %>%
  distinct() %>%
  right_join(dyntaxa_list) %>%
  filter(!is.na(taxon_id))

# Store file
write_delim(dyntaxa_list, "data_out/content/facts_external_links_dyntaxa.txt", delim = "\t") 
