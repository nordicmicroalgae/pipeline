library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Load stored file if running from cache
if(file.exists("cache/ncbi_cache.rda")) {
  load(file = "cache/ncbi_cache.rda")
} else {
  ncbi_records <- data.frame()
}

# Remove cached items
taxa_worms_missing <- taxa_worms %>%
  filter(!taxon_id %in% ncbi_records$taxon_id)

# Loop for each AphiaID
for(i in 1:length(taxa_worms_missing$taxon_id)) {
  cat('Getting NCBI records for taxa', i, 'of', length(taxa_worms_missing$taxon_id),'\n')
  record <- data.frame(taxon_id = taxa_worms_missing$taxon_id[i])
  tryCatch({
    record <- data.frame(taxon_id = taxa_worms_missing$taxon_id[i],
                         ncbi_id = wm_external(taxa_worms_missing$taxon_id[i],
                                               type = "ncbi")
    )  }, error=function(e){
      cat("Error occurred in AphiaID", taxa_worms_missing$taxon_id[i], ":", conditionMessage(e), "\n")
      
      # Introduce a delay of .5 seconds between iterations
      Sys.sleep(.5)
    })
  
  ncbi_records <- bind_rows(ncbi_records, record)
  
  # Store cached items
  save(ncbi_records, file = "cache/ncbi_cache.rda")
  
  # Introduce a delay of .5 seconds between iterations
  Sys.sleep(.5)
}

# Add URL
ncbi_list <- ncbi_records %>%
  filter(taxon_id %in% taxa_worms$taxon_id) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(ncbi_id)) %>%
  mutate(url = paste0("https://www.ncbi.nlm.nih.gov/datasets/taxonomy/", ncbi_id))

# Add URL
ena_list <- ncbi_records %>%
  filter(taxon_id %in% taxa_worms$taxon_id) %>%
  filter(!is.na(taxon_id)) %>%
  filter(!is.na(ncbi_id)) %>%
  mutate(url = paste0("www.ebi.ac.uk/ena/browser/view/", ncbi_id))

# Print output
print(paste(length(unique(ncbi_list$taxon_id)),
            "taxa found in NCBI"))

# Store file
write_delim(ncbi_list, "data_out/content/facts_external_links_ncbi.txt", delim = "\t") 
write_delim(ena_list, "data_out/content/facts_external_links_ena.txt", delim = "\t") 