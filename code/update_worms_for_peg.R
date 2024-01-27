library(tidyverse)
library(worrms)
library(writexl)

# Read current NOMP list
bvol_nomp <- read.table("data_in/bvol_nomp_version_2023.txt", header=TRUE, sep="\t", fill = TRUE)

# Filter PEG list and select relevant columns as a taxa list
taxa_list <- bvol_nomp %>%
  filter(List == "PEG_BVOL2023") %>%
  select(Species, Author, AphiaID) %>%
  distinct()

# Find taxa without AphiaID
missing_id <- taxa_list %>%
  filter(is.na(AphiaID)) %>%
  select(-AphiaID, Author)

# Extract records from WoRMS based on name for taxa with missing ID
missing_records <- data.frame()

# Loop for each name
for(i in 1:length(missing_id$Species)) {
  tryCatch({
    record <- wm_records_name(missing_id$Species[i], marine_only = FALSE)
    
    missing_records <- rbind(missing_records, record)
  }, error=function(e){})
  
  cat('Getting record', i, 'of', length(missing_id$Species),'\n')
}

# Wrangle names
new_id <- missing_id %>%
  rename(scientificname = Species) %>%
  left_join(missing_records) %>%
  select(scientificname, AphiaID) %>%
  rename(Species = scientificname,
         AphiaID_new = AphiaID) %>%
  mutate(comment = ifelse(!is.na(AphiaID_new), "Added AphiaID", NA))

# Replace AphiaID NAs in taxa list
taxa_list_updated <- taxa_list %>%
  left_join(new_id, by = "Species") %>%
  mutate(AphiaID = coalesce(AphiaID, AphiaID_new)) %>%
  select(-AphiaID_new)

# Compile unique AphiaIDs frin taxa list
aphia_id <- as.numeric(unique(taxa_list_updated$AphiaID))
aphia_id <- aphia_id[!is.na(aphia_id)]

# Extract records from WoRMS based on AphiaID
all_records <- data.frame()

# Loop for each AphiaID
for(i in 1:length(aphia_id)) {
  record <- wm_record(aphia_id[i])
  
  all_records <- rbind(all_records, record)
  
  cat('Getting record', i, 'of', length(aphia_id),'\n')
}

# Join records with taxa list
taxa_list_records <- taxa_list_updated %>%
  left_join(all_records, by = "AphiaID")

# Store file
write_delim(taxa_list_records, "data_out/peg_bvol_worms.txt", delim = "\t") 
write_xlsx(taxa_list_records, "data_out/peg_bvol_worms.xlsx")
