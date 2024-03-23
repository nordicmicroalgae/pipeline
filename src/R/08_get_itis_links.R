library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Load stored file if running from cache
if(file.exists("cache/itis_cache.rda")) {
  load(file = "cache/itis_cache.rda")
} else {
  itis_records <- data.frame()
}

# Remove cached items
taxa_worms <- taxa_worms %>%
  filter(!taxon_id %in% itis_records$taxon_id)

# Loop for each AphiaID
for(i in 1:length(taxa_worms$taxon_id)) {
  cat('Getting ITIS records for taxa', i, 'of', length(taxa_worms$taxon_id),'\n')
  record <- data.frame(taxon_id = taxa_worms$taxon_id[i])
  tryCatch({
    record <- data.frame(taxon_id = taxa_worms$taxon_id[i],
                         itis_id = wm_external(taxa_worms$taxon_id[i],
                                               type = "tsn")
    )  }, error=function(e){
      cat("Error occurred in iteration", i, ":", conditionMessage(e), "\n")
      
      # Introduce a delay of .5 seconds between iterations
      Sys.sleep(.5)
    })
  
  itis_records <- bind_rows(itis_records, record)
  
  # Store cached items
  save(itis_records, file = "cache/itis_cache.rda")
  
  # Introduce a delay of .5 seconds between iterations
  Sys.sleep(.5)
}

# Add URL
itis_list <- itis_records %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(itis_id)) %>%
  mutate(url = paste0("http://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=", itis_id))

# Print output
print(paste(length(unique(itis_list$taxon_id)),
            "taxa found in ITIS"))

# Store file
write_delim(itis_list, "data_out/content/facts_external_links_itis.txt", delim = "\t") 