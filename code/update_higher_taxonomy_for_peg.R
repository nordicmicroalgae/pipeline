library(tidyverse)

# Read current NOMP list
bvol_nomp <- read.table("data_in/bvol_nomp_version_2023.txt", header=TRUE, sep="\t", fill = TRUE)

# Read taxa_worms file
taxa_worms <- read_tsv("data_in/taxa_worms.txt")

# Read AB file
taxa_ab <- read_tsv("data_in/marie/facts_external_links_algaebase.txt")

bvol_taxa <- bvol_nomp %>%
  filter(List == "PEG_BVOL2023") %>%
  select(AphiaID,
         Species,
         Division,
         Class,
         Order,
         Genus
         # Author,
         ) %>%
  distinct() %>%
  mutate(Division = str_to_title(Division),
         Class = str_to_title(Class),
         Order = str_to_title(Order)) %>%
  rename(Division_peg = Division,
         Class_peg = Class,
         Order_peg = Order,
         Genus_peg = Genus,
         scientific_name_peg = Species,
         # Author_peg = Author
  )

worms_taxa <- taxa_worms %>%
  select(scientific_name,
         # authority,
         aphia_id,
         # kingdom,
         phylum,
         class,
         order,
         # family,
         genus
         ) %>%
  rename(scientific_name_worms = scientific_name,
         # Author_worms = authority,
         AphiaID = aphia_id,
         Phylum_worms = phylum,
         Class_worms = class,
         Order_worms = order,
         Genus_worms = genus
         ) %>%
  distinct()

ab_taxa <- taxa_ab %>%
  select(taxon_id,
         original_name,
         # ab_empire,
         # ab_kingdom,
         ab_phylum,
         ab_class,
         # ab_subclass,
         ab_order,
         # ab_family
         ) %>%
  rename(AphiaID = taxon_id,
         scientific_name_ab = original_name,
         Phylum_ab = ab_phylum,
         Class_ab = ab_class,
         Order_ab = ab_order) %>%
  mutate(scientific_name_ab = word(scientific_name_ab, 1, 2)) %>%
  distinct()
  

taxa_all <- bvol_taxa %>%
  left_join(worms_taxa) %>%
  left_join(ab_taxa)

taxa_wrong <- taxa_all %>%
  filter(!Class_peg == Class_worms | !Class_peg == Class_ab | !Order_peg == Order_worms | !Order_peg == Order_ab |!Genus_peg == Genus_worms) %>%
  relocate(Class_worms, .after = Class_peg) %>%
  relocate(Class_ab, .after = Class_worms) %>%
  relocate(Order_worms, .after = Order_peg) %>%
  relocate(Order_ab, .after = Order_worms) %>%
  relocate(Phylum_worms, .after = Division_peg) %>%
  relocate(Phylum_ab, .after = Phylum_worms) %>%
  relocate(scientific_name_worms, .after = scientific_name_peg) %>%
  relocate(scientific_name_ab, .after = scientific_name_worms) %>%
  mutate(mismatch_class = ifelse(Class_peg == Class_worms & Class_peg == Class_ab, NA, "x")) %>%
  mutate(mismatch_order = ifelse(Order_peg == Order_worms & Order_peg == Order_ab, NA, "x")) %>%
  mutate(mismatch_genus = ifelse(Genus_peg == Genus_worms, NA, "x")) %>%
  relocate(mismatch_genus) %>%
  relocate(mismatch_order) %>%
  relocate(mismatch_class)

# Store file
write_delim(taxa_wrong, "data_out/peg_higher_taxonomy.txt", delim = "\t", na = "") 
