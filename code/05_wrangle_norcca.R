library(tidyverse)
library(worrms)

# Read NORCCA taxa lists
norcca_worms <- read_tsv("data_in/norcca_extended_taxa_names_matched.txt",
                         col_types = cols()) # List of taxa that has been matched with the WoRMS web match interface
norcca_strains <- read_tsv("data_in/norcca_strains.txt",
                           col_types = cols())
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Fix column names and select relevant information
norcca_worms <- norcca_worms %>%
  rename(scientific_name = ScientificName...1,
         ScientificName = ScientificName...4,
         status = `Taxon status`) %>%
  select(scientific_name, status, AphiaID, AphiaID_accepted)

# Find taxa without AphiaID
missing_id <- norcca_strains %>%
  filter(!Species %in% norcca_worms$scientific_name) %>%
  mutate(scientific_name = gsub(" sp.", "", Species)) %>%
  mutate(scientific_name = str_trim(scientific_name))

# Create empty df
identified_taxa <- data.frame()

# Loop for each name to get AphiaID
for(i in 1:nrow(missing_id)) {
  tryCatch({
  missing_i <- missing_id[i,]
  
  missing_i$AphiaID = wm_name2id(missing_i$scientific_name)
  
  identified_taxa <- rbind(identified_taxa, missing_i)
  }, error=function(e){})
}

# Find all AphiaIDs
aphia_id <- unique(identified_taxa$AphiaID)

# Extract records from WoRMS based on AphiaID
missing_records <- data.frame()

# Loop for each AphiaID to get taxonomic records
for(i in 1:length(aphia_id)) {
  tryCatch({
  record <- wm_record(aphia_id[i])
  
  missing_records <- rbind(missing_records, record)
  }, error=function(e){})
  
  cat('Getting record', i, 'of', length(aphia_id),'\n')
}

# Keep only necessary info
missing_info <- identified_taxa %>%
  left_join(missing_records, by = "AphiaID") %>%
  select(Species, status, AphiaID, valid_AphiaID) %>%
  rename(scientific_name = Species,
         AphiaID_accepted = valid_AphiaID) %>%
  distinct()

# Combine manually matched names with the missing info
norcca_worms <- bind_rows(norcca_worms, missing_info)

# Join tables
norcca_combined <- norcca_strains %>%
  mutate(scientific_name = Species) %>%
  left_join(norcca_worms, by = "scientific_name") %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", AphiaID_accepted, AphiaID),
         scientific_name = gsub(" sp.", "", scientific_name)) %>%
  select(-status, -AphiaID, -AphiaID_accepted) %>%
  rename(taxon_id = used_aphia_id) %>%
  filter(taxon_id %in% taxa_worms$taxon_id) %>%
  mutate(`Strain name` = toupper(gsub('.*strain/', '', `Strain Link`)))

# Make snakecase headers
names(norcca_combined) <- snakecase::to_snake_case(names(norcca_combined))

# Print output
print(paste("Information from",
            length(unique(norcca_combined$`Strain name`)),
            "strains extracted from NORCCA, matching",
            length(unique(norcca_combined$scientific_name)),
            "NuA taxa"))

# Store file
write_tsv(norcca_combined, "data_out/content/facts_external_links_norcca.txt", na = "")