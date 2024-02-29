library(tidyverse)
library(worrms)

# Find the latest bvol file
bvol_filename <- list.files("data_in") %>%
  as_tibble() %>%
  filter(agrepl("bvol", value)) %>%
  arrange(value)

# Read current NOMP list
bvol_nomp <- read.table(file.path("data_in", bvol_filename$value[nrow(bvol_filename)]), 
                        header=TRUE, 
                        sep="\t", 
                        encoding = "latin1",
                        fill = TRUE)

# Read NORCCA culture list with AphiaID through WoRMS match web function
# norcca <- read.table("data_in/norcca.txt", header=TRUE, sep="\t", fill = TRUE)

# Read HAB list with AphiaID through WoRMS match web function
# ioc_hab <- read.table("data_in/nordic_hab_karlson_et_al_2021.txt", header=TRUE, sep="\t", fill = TRUE)

# Read a WoRMS-matched species list from old NuA
old_nua <- read.table("data_in/old_nua_matched.txt", header=TRUE, sep="\t", fill = TRUE, quote = "", encoding = "UTF-8")

# Combine unqiue AphiaIDs from NOMP, NORCCA, IOC-HAB and the old NuA species list
aphia_id_combined <- as.numeric(unique(c(bvol_nomp$AphiaID, old_nua$AphiaID)))
aphia_id_combined <- aphia_id_combined[!is.na(aphia_id_combined)]

# Extract records from WoRMS based on AphiaID
all_records <- data.frame()

# Loop for each AphiaID
for(i in 1:length(aphia_id_combined)) {
  record <- wm_record(aphia_id_combined[i])
  
  all_records <- rbind(all_records, record)
  
  cat('Getting record', i, 'of', length(aphia_id_combined),'\n')
}

# Translate unaccepted names, remove blank names (deleted/quaratine), remove flagellates (146222)
all_records <- all_records %>%
  mutate(used_aphia_id = ifelse(status == "unaccepted", valid_AphiaID, AphiaID)) %>%
  filter(!is.na(scientificname)) %>%
  filter(!AphiaID == 146222)

# Summarise translated unaccepted names
translate <- all_records %>%
  filter(used_aphia_id != AphiaID) %>%
  select(scientificname, AphiaID, valid_name, valid_AphiaID) %>%
  rename(scientific_name = scientificname,
         aphia_id = AphiaID,
         scientific_name_accepted = valid_name,
         aphia_id_accepted = valid_AphiaID)

# Store files, use used_aphia_id_list.txt in https://github.com/nordicmicroalgae/taxa-worms to build taxa_worms.txt
write_delim(translate, "data_out/translate_to_worms.txt", delim = "\t") 
write_delim(all_records, "data_in/used_aphia_id_list.txt", delim = "\t") 
