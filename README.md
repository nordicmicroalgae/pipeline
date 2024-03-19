# Repo for updating Nordic Microalgae content/species

The R Markdown document update-nua-taxonomy.Rmd calls a number of R and Python scripts to interact with APIs and webpages from [WoRMS](https://www.marinespecies.org/), [Dyntaxa](https://namnochslaktskap.artfakta.se/), [AlgaeBase](https://www.algaebase.org/), [GBIF](https://www.gbif.org/), [NORCCA](https://norcca.scrol.net/) in order to update the [species content](https://github.com/nordicmicroalgae/content/tree/master/species) of Nordic Microalgae. In order to run the full update, additional repos from [https://github.com/nordicmicroalgae](https://github.com/nordicmicroalgae) are required and placed in the directory structure outlined below. 

The R package [SHARK4R](https://github.com/sharksmhi/SHARK4R/) is required for some API queries. API query functions towards AlgaeBase have been modified from the algaeClassify package (Patil et al. 2023). Store your API keys to Dyntaxa and AlgaeBase in /update-nua-taxonomy/.Renviron.

### References
Patil, V.P., Seltmann, T., Salmaso, N., Anneville, O., Lajeunesse, M., Straile, D., 2023. algaeClassify (ver 2.0.1, October 2023): U.S. Geological Survey software release, https://doi.org/10.5066/F7S46Q3F

## To update the content:
* Clone this repo and other required repos, and place in the directory structure as outlined below
* Download the latest NOMP biovolume list (in .xlsx) and store in /update-nua-taxonomy/data_in/. The file can be accessed from the [Nordic Microalgae webpage](http://nordicmicroalgae.org/tools)
* Download the latest complete IOC HAB list in .txt from this [link](https://www.marinespecies.org/hab/aphia.php?p=download&what=taxlist) and store in /update-nua-taxonomy/data_in/
* Additional taxa that exist in WoRMS can be manually added to the database in /update-nua-taxonomy/data_in/additions_to_old_nua.txt
* Run /update-nua-taxonomy.Rmd. The API calls will take 6-7 hours to run if lists are not loaded from cache
* Check output for potential duplicated taxa or errors, they are listed in the .html report in /update-nua-taxonomy/update_history/
  * Taxa may be filtered using /update-nua-taxonomy/data_in/blacklist.txt and /update-nua-taxonomy/data_in/whitelist.txt, if needed
* Push updated lists from /update-nua-taxonomy/data_out/content to https://github.com/nordicmicroalgae/content/
* Run the syncdb app as a superuser from the admin pages, see logs for potential problems
* Check if any images become assinged as taxon = 'none' in the admin page after importing new taxa lists, and assign them to their current names.
* Verify updated Quick-View filters in /update-nua-taxonomy/data_out/backend/taxa/config and push to https://github.com/nordicmicroalgae/backend
  * Corrections can be made in /update-nua-taxonomy/data_in/plankton_groups.txt, where major groups can be defined for Kingdom and Phylum. 'Other microalgae' are defined as everything else except groups specified under exclude_from_others
* Upload a new version of the checklist to data.smhi.se

## Required repos:

https://github.com/nordicmicroalgae/taxa-worms

https://github.com/nordicmicroalgae/norcca_compiler

## Directory structure
```
/
├─ norcca_compiler/
│  └─ norcca_compiler/
├─ taxa_worms/
│  ├─ data_in/
│  ├─ data_out/
│  └─ wormsextractor/
└─ update-nua-taxonomy/
   ├─ cache/
   ├─ code/
   │  └─ fun/
   ├─ data_in/
   ├─ data_out/
   │  ├─ content/
   │  └─ backend/
   │     └─ taxa/
   │        └─ config/
   └─ update_history/
```
