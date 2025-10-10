library(tidyverse)
library(yaml)

# Read taxa_worms file
plankton_groups <- read_tsv("data_in/plankton_groups.txt",
                       col_types = cols())

# Find the Kingdoms
kingdom <- plankton_groups %>%
  filter(rank == "Kingdom")

# Find the Phyla
phylum <- plankton_groups %>%
  filter(rank == "Phylum")

# Find the Class
class <- plankton_groups %>%
  filter(rank == "Class")

# Select phylum and kingdom to be excluded from "other microalgae"
kingdom_exclude <- c(paste(kingdom$included_taxa))
phylum_exclude <- c(paste(phylum$included_taxa))
class_exclude <- c(paste(class$included_taxa))

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
  filter(!phylum %in% phylum_exclude & !kingdom %in% kingdom_exclude & !class %in% class_exclude)

# Create a dataframe with all classes within the other microalgae group
other <- data.frame(included_taxa = paste0(sort(unique(others$class)))) %>%
  mutate(group_name = "Other microalgae",
         rank = "Class")

# Bind tables and remove unwanted information
filters <- rbind(plankton_groups, other) %>%
  filter(!grepl("exclude", group_name)) %>%
  select(-rank)

# Group the dataframe by group_name and collect included_taxa as a list
grouped_df <- filters %>%
  group_by(group_name) %>%
  summarize(included_taxa = list(included_taxa))

# Create a list to hold the final YAML structure
yaml_list <- list()

# Construct the YAML structure for each group
for (i in 1:nrow(grouped_df)) {
  group <- grouped_df$group_name[i]
  taxa <- grouped_df$included_taxa[[i]]
  
  # If there's only one included_taxa, convert it to a list
  if (length(taxa) == 1) {
    taxa <- list(taxa)
  }
  
  group_entry <- list(group_name = group, included_taxa = taxa)
  yaml_list <- c(yaml_list, list(group_entry))
}

# Find all subspecies ranks
subspecies <- taxa_worms %>%
  filter(!is.na(genus)) %>%
  filter(!rank == "Genus")

# Create a list for the species_or_below field
species_or_below <- as.list(sort(unique(subspecies$rank)))

# Create the YAML output with both fields on the same level
yaml_output <- c("# Definition of ranks considered to be 'species or below'",
                 as.yaml(list(species_or_below = species_or_below)), 
                 "# Definition of 'group of organisms'. Each group consists of two elements:",
                 "#     `group_name`",
                 "#         The name or label of the group. This is for example the text being",
                 "#         shown in the 'quick view' user interface.",
                 "#     `included_taxa`",
                 "#         Should contain a list of scientific names. The names should be",
                 "#         taxonomical parents, at any level, for which subordinate taxa to",
                 "#         include in the group.",
                 as.yaml(list(groups_of_organisms = yaml_list)))

# Load yaml
new_yaml <- yaml.load(yaml_output)

zip_url <- "https://github.com/nordicmicroalgae/backend/archive/refs/heads/master.zip"

# Temporary download location
tmp <- tempfile(fileext = ".zip")
utils::download.file(zip_url, tmp)

unpack_dir <- tempdir()
utils::unzip(tmp, exdir = unpack_dir)

current_yaml <- file.path(unpack_dir, "backend-master", "taxa", "config", "filters.yaml")

yaml_content <- readLines(current_yaml)
backend_yaml <- yaml.load(yaml_content)

# Print warning if filters differ
if (!identical(new_yaml, backend_yaml)) {
  cat(paste("Warning: Quick-view filter content has changed, please consider to update filters in backend"))
} else {
  cat(paste("Info: Quick-view filters are identical to current backend version, no need to update backend"))
}

# Write YAML to file
writeLines(yaml_output, "data_out/backend/taxa/config/filters.yaml")
