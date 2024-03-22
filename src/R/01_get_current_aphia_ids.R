library(tidyverse)
library(worrms)
library(readxl)

# Find the latest bvol file
bvol_filename <- list.files("data_in") %>%
  as_tibble() %>%
  filter(agrepl("bvol", value)) %>%
  filter(agrepl(".xlsx", value)) %>%
  filter(!agrepl("~$", value)) %>%
  arrange(value)

# Read current NOMP list
bvol_nomp <- read_excel(file.path("data_in", bvol_filename$value[nrow(bvol_filename)])) %>%
  mutate(Calculated_volume_µm3 = round(Calculated_volume_µm3, 6),
         `Calculated_Carbon_pg/counting_unit` = round(`Calculated_Carbon_pg/counting_unit`, 6)) %>%
  select(-contains("NOT IMPORTED"))

names(bvol_nomp) <- gsub("\\r\\n", "", names(bvol_nomp))
names(bvol_nomp) <- gsub("\\n", "", names(bvol_nomp))

# Read a WoRMS-matched species list from old NuA
old_nua <- read.table("data_in/database_export_old_nua.txt", header=TRUE, sep="\t", fill = TRUE, quote = "", encoding = "UTF-8")

# Read HAB list from Karlson et al 2021 https://doi.org/10.1016/j.hal.2021.101989
nordic_hab_karlson <- read_tsv("data_in/facts_hab_ioc_karlson_et_al_2021.txt",
                               col_types = cols())

# Read blacklist for removing unwanted
additions <- read_tsv("data_in/additions_to_old_nua.txt")

# Read blacklist for removing unwanted
blacklist <- read_tsv("data_in/blacklist.txt")

# Combine unqiue AphiaIDs from NOMP, NORCCA, IOC-HAB and the old NuA species list
aphia_id_combined <- as.numeric(unique(c(bvol_nomp$AphiaID, old_nua$AphiaID, additions$AphiaID, nordic_hab_karlson$taxon_id)))
aphia_id_combined <- aphia_id_combined[!is.na(aphia_id_combined)]

# Load stored file if running from cache
if(file.exists("cache/all_records_cache.rda")) {
  load(file = "cache/all_records_cache.rda")
} else {
  all_records <- data.frame()
}

# Skip cached items
aphia_id_combined <- aphia_id_combined[!aphia_id_combined %in% all_records$AphiaID]

# Extract records from WoRMS based on AphiaID
if(length(aphia_id_combined) > 0) {
  for(i in 1:length(aphia_id_combined)) {
    record <- wm_record(aphia_id_combined[i])
    
    all_records <- rbind(all_records, record)
    
    cat('Getting record', i, 'of', length(aphia_id_combined),'\n')
    save(all_records, file = "cache/all_records_cache.rda")
  }
}

# Update taxon_id for NOMP list
bvol_nomp <- all_records %>% 
  select(AphiaID, status, valid_AphiaID, valid_name) %>%
  right_join(bvol_nomp) %>%
  mutate(taxon_id = ifelse(status == "unaccepted", valid_AphiaID, AphiaID)) %>%
  mutate(taxon_id = ifelse(status == "deleted", valid_AphiaID, taxon_id)) %>%
  relocate(taxon_id) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!AphiaID %in% blacklist$taxon_id)

# Translate unaccepted names, remove blank names (deleted/quaratine), remove flagellates (146222)
all_records <- all_records %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", valid_AphiaID, AphiaID)) %>%
  mutate(used_aphia_id = ifelse(status == "deleted", valid_AphiaID, used_aphia_id)) %>%
  mutate(scientificname = ifelse(status == "deleted", valid_name, scientificname)) %>%
  filter(!is.na(scientificname)) %>%
  filter(!AphiaID %in% blacklist$taxon_id)

# Summarise translated unaccepted names
translate <- all_records %>%
  filter(used_aphia_id != AphiaID) %>%
  select(scientificname, AphiaID, valid_name, valid_AphiaID) %>%
  rename(scientific_name = scientificname,
         aphia_id = AphiaID,
         scientific_name_accepted = valid_name,
         aphia_id_accepted = valid_AphiaID)

# Store files, use used_aphia_id_list.txt in https://github.com/nordicmicroalgae/taxa-worms to build taxa_worms.txt
write_tsv(translate, "data_out/translate_to_worms.txt")
write_tsv(all_records, "data_in/used_aphia_id_list.txt")
write_tsv(bvol_nomp, "data_out/content/facts_biovolumes_nomp.txt", na = "")
