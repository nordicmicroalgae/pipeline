library(tidyverse)
library(SHARK4R)
library(worrms)

# Get current HAB list
hab_list <- get_hab_list()

# Read HAB list from Karlson et al 2021 https://doi.org/10.1016/j.hal.2021.101989
nordic_hab_karlson <- read_tsv("data_in/facts_hab_ioc_karlson_et_al_2021.txt",
                       col_types = cols())

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Get all aphia_id
aphia_id <- unique(nordic_hab_karlson$taxon_id)

# Extract records from WoRMS based on AphiaID
karlson_records <- data.frame()

# Loop for each AphiaID to get taxonomic records
for(i in 1:length(aphia_id)) {
  tryCatch({
    record <- wm_record(aphia_id[i])
    
    karlson_records <- rbind(karlson_records, record)
    
    cat('Getting record', i, 'of', length(aphia_id),'\n')
  }, error=function(e){
    cat("Error occurred in AphiaID", aphia_id[i], ":", conditionMessage(e), "\n")
  })
}

# Update AphiaID if id is unaccepted
nordic_hab_karlson_updated <- karlson_records %>%
  select(AphiaID, valid_AphiaID, status) %>%
  rename(taxon_id = AphiaID) %>%
  right_join(nordic_hab_karlson, by = "taxon_id") %>%
  mutate(taxon_id = ifelse(status == "unaccepted", valid_AphiaID, taxon_id)) %>%
  mutate(taxon_id = ifelse(status == "deleted", valid_AphiaID, taxon_id)) %>%
  select(-valid_AphiaID, -status)
  
# Select nordic taxa and wrangle list
nordic_hab <- hab_list %>%
  filter(AphiaID %in% taxa_worms$taxon_id) %>%
  filter(taxonRank %in% c("Species","Variety","Forma","Subspecies")) %>%
  select(ScientificName, AphiaID) %>%
  mutate(link = paste0("https://www.marinespecies.org/hab/aphia.php?p=taxdetails&id=",
                AphiaID)) %>%
  rename(taxon_id = AphiaID,
         scientific_name = ScientificName)

# Print output
print(paste(length(unique(nordic_hab$taxon_id)),
            "IOC HAB species found in database"))

# Store files
write_tsv(nordic_hab, "data_out/content/facts_external_links_hab_ioc.txt")
write_tsv(nordic_hab_karlson_updated, "data_out/content/facts_hab_ioc_karlson_et_al_2021.txt") 
