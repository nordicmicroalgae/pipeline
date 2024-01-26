library(tidyverse)

# Match taxa_worms with Dyntaxa through the web match interface, read .txt-file here
dyntaxa_records <- read.table("data_in/dyntaxa_match.txt", header=TRUE, sep="\t", fill = TRUE, quote = "")

# Get Dyntaxa synonyms, did not work well
dyntaxa_synonyms <- dyntaxa_records %>%
  select(Taxon.id, Synonymer) %>%
  filter(!Synonymer == "") %>%
  rename(dyntaxa_id = Taxon.id) %>%
  left_join(dyntaxa_list)