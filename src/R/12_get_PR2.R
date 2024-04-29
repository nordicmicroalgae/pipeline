library(pr2database)
library(tidyverse)

# Load PR2 database
pr2 <- pr2_database()

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Filter taxa present in database
nordic_pr2 <- pr2 %>%
  filter(worms_id %in% taxa_worms$taxon_id) %>%
  select(worms_id, species) %>%
  distinct() %>%
  arrange(species) %>%
  mutate(url = "https://app.pr2-database.org/pr2-database/") %>%
  rename(taxon_id = worms_id,
         pr2_name = species)

# Store file
write_delim(nordic_pr2, "data_out/content/facts_external_links_pr2.txt", delim = "\t") 