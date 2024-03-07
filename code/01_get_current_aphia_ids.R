library(tidyverse)
library(worrms)

# Find the latest bvol file
bvol_filename <- list.files("data_in") %>%
  as_tibble() %>%
  filter(agrepl("bvol", value)) %>%
  arrange(value)

# Read current NOMP list
bvol_nomp <- read_tsv(file.path("data_in", bvol_filename$value[nrow(bvol_filename)]),
                      locale = locale(encoding = "latin1")) %>%
  select(where(~ !(all(is.na(.)))))

names(bvol_nomp) <- gsub("\\n", "", names(bvol_nomp))

# Read a WoRMS-matched species list from old NuA
old_nua <- read.table("data_in/old_nua_matched.txt", header=TRUE, sep="\t", fill = TRUE, quote = "", encoding = "UTF-8")

# Read blacklist for removing unwanted
blacklist <- read_tsv("data_in/blacklist.txt")

# Combine unqiue AphiaIDs from NOMP, NORCCA, IOC-HAB and the old NuA species list
aphia_id_combined <- as.numeric(unique(c(bvol_nomp$AphiaID, old_nua$AphiaID)))
aphia_id_combined <- aphia_id_combined[!is.na(aphia_id_combined)]

# Load stored file if running from cache
if(file.exists("all_records_cache.rda")) {
  load(file = "all_records_cache.rda")
} else {
  # Extract records from WoRMS based on AphiaID
  all_records <- data.frame()
  
  # Loop for each AphiaID to get taxonomic records
  for(i in 1:length(aphia_id_combined)) {
    record <- wm_record(aphia_id_combined[i])
    
    all_records <- rbind(all_records, record)
    
    cat('Getting record', i, 'of', length(aphia_id_combined),'\n')
  }
  save(all_records, file = "all_records_cache.rda")
}

# Translate unaccepted names, remove blank names (deleted/quaratine), remove flagellates (146222)
all_records <- all_records %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", valid_AphiaID, AphiaID)) %>%
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
