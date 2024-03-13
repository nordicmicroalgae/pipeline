library(tidyverse)
library(worrms)

# Read taxa_worms file
taxa_worms <- read_tsv("data_out/content/taxa.txt",
                       col_types = cols())

# Get NCBI id from WoRMS
ncbi_records <- data.frame()

# Load stored file if running from cache
if(file.exists("ncbi_cache.rda")) {
  load(file = "ncbi_cache.rda")
} else {
  # Loop for each AphiaID
  for(i in 1:length(taxa_worms$taxon_id)) {
    tryCatch({
      record <- data.frame(taxon_id = taxa_worms$taxon_id[i],
                           ncbi_id = wm_external(taxa_worms$taxon_id[i],
                                                 type = "ncbi")
      )
      
      ncbi_records <- rbind(ncbi_records, record)
    }, error=function(e){})
    cat('Getting NCBI records for taxa', i, 'of', length(taxa_worms$taxon_id),'\n')
  }
  save(ncbi_records, file = "ncbi_cache.rda")
}

# Add URL
ncbi_list <- ncbi_records %>%
  filter(!is.na(taxon_id)) %>%
  mutate(url = paste0("https://www.ncbi.nlm.nih.gov/datasets/taxonomy/", ncbi_id))

# Add URL
ena_list <- ncbi_records %>%
  filter(!is.na(taxon_id)) %>%
  mutate(url = paste0("www.ebi.ac.uk/ena/browser/view/", ncbi_id))

# Print output
print(paste(length(unique(ncbi_list$taxon_id)),
            "taxa found in NCBI"))

# Store file
write_delim(ncbi_list, "data_out/content/facts_external_links_ncbi.txt", delim = "\t") 
write_delim(ena_list, "data_out/content/facts_external_links_ena.txt", delim = "\t") 