library(SHARK4R)
library(tidyverse)

# Get taxa information
taxa <- get_nua_taxa()

# Get external links
external_links <- get_nua_external_links(taxa$slug)

# Get media links
media <- get_nua_media_links()

# Combine the tables
algaebase <- taxa %>%
  left_join(external_links) %>%
  filter(provider == "AlgaeBase") %>%
  left_join(media, relationship = "many-to-many")

# Save file
write.table(algaebase,
            "data_out/algaebase_links2.txt",
            na = "",
            quote = FALSE,
            row.names = FALSE,
            sep = "\t",
            fileEncoding = "UTF-8")
