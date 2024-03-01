library(tidyverse)

# Find the latest HAB list
hab_filename <- list.files("data_in") %>%
  as_tibble() %>%
  filter(agrepl("HABs_taxlist_", value)) %>%
  arrange(value)

# Read current HAB list
hab_list <- read.table(file.path("data_in", hab_filename$value[nrow(hab_filename)]), 
                        header=TRUE, 
                        sep="\t", 
                        encoding = "WINDOWS-1252",
                        fill = TRUE)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt")

# Select nordic taxa and wrangle list
nordic_hab <- hab_list %>%
  filter(AphiaID %in% taxa_worms$taxon_id) %>%
  filter(taxonRank == "Species") %>%
  select(ScientificName, AphiaID) %>%
  mutate(link = paste0("https://www.marinespecies.org/hab/aphia.php?p=taxdetails&id=",
                AphiaID)) %>%
  rename(taxon_id = AphiaID,
         scientific_name = ScientificName)

# Store file
write_tsv(nordic_hab, "data_out/content/facts_external_links_hab_ioc.txt") 