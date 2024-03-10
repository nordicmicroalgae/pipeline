library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Get ITIS id from WoRMS
itis_records <- data.frame()

# Load stored file if running from cache
if(file.exists("itis_cache.rda")) {
  load(file = "itis_cache.rda")
} else {
  # Loop for each AphiaID
  for(i in 1:length(taxa_worms$taxon_id)) {
    tryCatch({
      record <- data.frame(taxon_id = taxa_worms$taxon_id[i],
                           itis_id = wm_external(taxa_worms$taxon_id[i],
                            type = "tsn")
                           )
      
      itis_records <- rbind(itis_records, record)
    }, error=function(e){})
    cat('Getting ITIS records for taxa', i, 'of', length(taxa_worms$taxon_id),'\n')
  }
  save(itis_records, file = "itis_cache.rda")
}

# Add URL
itis_list <- itis_records %>%
  filter(!is.na(taxon_id)) %>%
  mutate(url = paste0("http://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=", itis_id))

# Print output
print(paste(length(unique(itis_list$taxon_id)),
            "taxa found in ITIS"))

# Store file
write_delim(itis_list, "data_out/content/facts_external_links_itis.txt", delim = "\t") 