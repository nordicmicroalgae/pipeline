# Nordic Microalgae: Data pipeline

This repository contains R and Python scripts designed to gather the necessary data for updating the taxonomic backbone of Nordic Microalgae. The process involves interacting with various APIs and webpages from key sources including [WoRMS](https://www.marinespecies.org/), [Dyntaxa](https://namnochslaktskap.artfakta.se/), [AlgaeBase](https://www.algaebase.org/), [GBIF](https://www.gbif.org/), [NORCCA](https://norcca.scrol.net/), and [SHARKdata](https://sharkdata.smhi.se/). The taxonomic data pipeline is initiated through the execution of the R Markdown document `update-nua-taxonomy.Rmd`. The data is input manually into the [content](https://github.com/nordicmicroalgae/content), which is then integrated into the [backend](https://github.com/nordicmicroalgae/backend).

## Prerequisites
- Python interpreter installed for use in R with the `reticulate` package. Refer to [rstudio.github.io/reticulate](https://rstudio.github.io/reticulate/) for details.
- Install the R package `SHARK4R` for API queries towards Dyntaxa. See installation details on [github.com/sharksmhi/SHARK4R/](https://github.com/sharksmhi/SHARK4R/).
- Obtain API keys for Dyntaxa and AlgaeBase. To acquire a key for Dyntaxa, subscribe to the 'Taxonomy' product via the [SLU Artdatabanken developer portal](https://api-portal.artdatabanken.se/). Request keys from AlgaeBase directly from their developer team.  Store your API keys in `.Renviron`. Use the provided function to edit this file easily:

```
install.packages("usethis")
usethis::edit_r_environ("project")
```
Edit your .Renviron to look like this (fake checksums provided below):
```
ALGAEBASE_APIKEY = "e1482dc9abfe073d56db08c0b604e333"
DYNTAXA_APIKEY = "89ad0b9cac6ce53184cc942147e1f06f"
```

API query functions towards AlgaeBase have been modified (stored in `/src/R/fun`) from the ```algaeClassify``` package to include AlgaeBase IDs (Patil et al. 2023).

## Update Process
Follow these steps to update the species content:
1. Clone this repository.
2. Store your API keys in `.Renviron` as instructed above.
3. Download the latest NOMP biovolume list (in .xlsx format) from the [Nordic Microalgae webpage](http://nordicmicroalgae.org/tools) and save it in `/data_in/`.
4. Download the latest complete IOC HAB list in .txt format from the [IOC-UNESCO Taxonomic Reference List of HAB](https://www.marinespecies.org/hab/aphia.php?p=download&what=taxlist) and store it in `/data_in/`.
5. If needed, manually add additional taxa existing in WoRMS to the database in `/data_in/additions_to_old_nua.txt`.
6. Run the `update-nua-taxonomy.Rmd` script. Note that API calls may take 10-11 hours to run if lists are not loaded from cache.
7. Check the output for potential duplicated taxa names, errors or missing taxa listed in the .html report in `/update_history/`. Taxa can be excluded using `/data_in/blacklist.txt`, while unaccepted taxa can be enforced to remain using `/data_in/whitelist.txt`. Return to Step 5 to include additional taxa (set cache = TRUE and run the script again).
8. Push updated lists from `/data_out/content` to [nordicmicroalgae/content/species](https://github.com/nordicmicroalgae/content/tree/master/species) and verify GitHub CI checks.
9. Run the syncdb app as a superuser from the admin pages to import the new species content into the backend. Check logs for potential problems.
10. Check for any images assigned as taxon = 'none' after the import and assign them to their current names.
11. Verify updated Quick-View filters in `/data_out/backend/taxa/config` and push to [nordicmicroalgae/backend](https://github.com/nordicmicroalgae/backend) if needed.
12. Corrections to the Quick-View filters can be made in `/data_in/plankton_groups.txt`, defining major groups for Kingdom and Phylum. 'Other microalgae' are defined as everything else except groups specified under `exclude_from_others`.
13. Upload new .xlsx and .txt versions of the checklist from `/data_out/` to data.smhi.se.

## Workflow

The data pipeline builds upon the existing taxonomy in WoRMS, translating only unaccepted and deleted taxa. It is rooted in the database of the previous version of Nordic Microalgae, supplemented by taxa from the NOMP biovolume file, HAB taxa sourced from Karlson et al. 2021, and additional manually curated taxa. Higher taxonomic classifications are aggregated from all parent taxa, redirecting them to their closest accepted relatives. Links and factual data are gathered via diverse API calls and integrated into the database (`taxa.txt`) using their corresponding taxon_id (current AphiaID). Information from the NORCCA culture collection is acquired through HTML scraping, with links to all strains originating from Northern Europe cataloged and stored. The extensive IOC HAB and NORCCA lists are filtered down to the species present in the database. In addition, the taxonomic content is compared to the phytoplankton taxa present in the "Svenskt HavsARKivs" (SHARK) database.

```mermaid
flowchart TD
    A[Old NµA database] -->|AphiaID| E(Get current AphiaIDs from WoRMS)
    B[NOMP] -->|AphiaID| E(Get current AphiaIDs from WoRMS)
    C['Nordic HAB list', Karlson et al. 2021] -->|AphiaID| E(Get current AphiaIDs from WoRMS)
    D[Additions] -->|AphiaID| E(Get current AphiaIDs from WoRMS)
    E --> F[Construct taxonomical tree
    taxa_worms]
    E --->|NOMP| G(facts_biovolumes_nomp.txt)
    E --->|'Nordic HAB list'| Q(facts_hab_ioc_karlson_et_al_2021.txt)
    F --> |Accepted AphiaID, redirect parents|H[(taxa.txt)]
    H --> |API calls| K(facts_external_links_algaebase.txt
    facts_external_links_dyntaxa.txt
    facts_external_links_worms.txt 
    facts_external_links_itis.txt
    facts_external_links_ncbi.txt
    facts_external_links_ena.txt
    facts_external_links_gbif.txt
    synonyms.txt )
    I[NORCCA] -.-|Web scrape| H -.-|Filter Nordic culture strains & HABs|J(facts_external_links_hab_ioc.txt
    facts_external_links_norcca.txt)
    L[IOC HAB list] -.- H
    H --> M[filters.yaml]
```
## References

- Karlson, B., Andersen, P., Arneborg, L., Cembella, A., Eikrem, W., John, U., West, J.J., Klemm, K., Kobos, J., Lehtinen, S., Lundholm, N., Mazur-Marzec, H., Naustvoll, L., Poelman, M., Provoost, P., De Rijcke, M., Suikkanen, S., 2021. Harmful algal blooms and their effects in coastal seas of Northern Europe. Harmful Algae. Feb;102:101989. doi: [10.1016/j.hal.2021.101989](https://doi.org/10.1016/j.hal.2021.101989). Epub 2021 Mar 6. PMID: 33875185.
- Patil, V.P., Seltmann, T., Salmaso, N., Anneville, O., Lajeunesse, M., Straile, D., 2023. algaeClassify (ver 2.0.1, October 2023): U.S. Geological Survey software release, https://doi.org/10.5066/F7S46Q3F
