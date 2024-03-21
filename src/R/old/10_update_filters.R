library(tidyverse)
library(yaml)

# Read taxa_worms file
plankton_groups <- read_tsv("data_in/plankton_groups.txt",
                       col_types = cols())

# # Define major groups
# diatoms <- filter(plankton_groups, group_name=="Diatoms")$included_taxa
# dinoflagellates <- filter(plankton_groups, group_name=="Dinoflagellates")$included_taxa
# ciliates <- filter(plankton_groups, group_name=="Ciliates")$included_taxa
# cyanobacteria <- filter(plankton_groups, group_name=="Cyanobacteria")$included_taxa
# protozoa <- filter(plankton_groups, group_name=="Protozoa")$included_taxa

kingdom <- plankton_groups %>%
  filter(rank == "Kingdom")

phylum <- plankton_groups %>%
  filter(rank == "Phylum")

# Select phylum and kingdom to be excluded from "other microalgae"
kingdom_exclude <- c(paste(kingdom$included_taxa))
phylum_exclude <- c(paste(phylum$included_taxa))

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Find if names are missing from taxa.txt
unknown_names <- data.frame(name = c(phylum_exclude, kingdom_exclude)) %>%
  filter(!name %in% c(taxa_worms$kingdom, taxa_worms$phylum)) %>%
  distinct()

# Print warning message
if(nrow(unknown_names)>0) {
  cat(paste("Warning:", paste(unknown_names$name, collapse = ", "), "no longer exist in taxa.txt, please update plankton_groups.txt to valid names"))
}

# Summarize higher taxonomy
higher_taxa <- taxa_worms %>%
  select(kingdom, phylum, class, family, classification) %>%
  distinct()

# Find classes for all "other microalgae"
others <- higher_taxa %>%
  filter(!phylum %in% phylum_exclude & !kingdom %in% kingdom_exclude)

# Find classes
# other_classes <- paste0("      - ", sort(unique(others$class)))
other_classes <- paste0(sort(unique(others$class)))

other <- data.frame(included_taxa = paste0(sort(unique(others$class)))) %>%
  mutate(group_name = "Other microalgae",
         rank = "Class")


filters <- rbind(plankton_groups, other) %>%
  filter(!grepl("exclude", group_name)) %>%
  select(-rank)

# 
data.frame(included_taxa = c(ciliates, cyanobacteria, diatoms, dinoflagellates, other_classes, protozoa))

filters <- data.frame(included_taxa = c(ciliates, cyanobacteria, diatoms, dinoflagellates, other_classes, protozoa)) %>%
  mutate(group_name = ifelse(included_taxa == ciliates, "Ciliates", NA)) %>%
  mutate(group_name = ifelse(included_taxa == cyanobacteria, "Cyanobacteria", group_name)) %>%
  mutate(group_name = ifelse(included_taxa == diatoms, "Diatoms", group_name)) %>%
  mutate(group_name = ifelse(included_taxa == dinoflagellates, "Dinoflagellates", group_name)) %>%
  mutate(group_name = ifelse(included_taxa %in% other_classes, "Other microalgae", group_name)) %>%
  mutate(group_name = ifelse(included_taxa == protozoa, "Protozoa", group_name))


nested_lists <- filters %>%
  split(f = .$group_name) %>%
  purrr::map(dplyr::select, -group_name) %>%
  purrr::map(~ split(.x, f = .x$included_taxa)) %>%
  purrr::map_depth(2, dplyr::select, -included_taxa) %>%
  list(groups_of_organisms = .)

# filename <- tempfile()
# con <- file(filename, "w")
# write_yaml(filters, con)
# close(con)
# 


# using a filename to specify output file
write_yaml(nested_lists, "data_out/filters.yaml")


# Store table
write.table(other_classes, "data_out/filters.txt", row.names = FALSE, quote = FALSE)
