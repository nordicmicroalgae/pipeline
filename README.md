# Repo for updating Nordic Microalgae content/species

The R Markdown document update-nua-taxonomy.Rmd calls a number of R and Python scripts to interact with APIs and webpages from [WoRMS](https://www.marinespecies.org/), [Dyntaxa](https://namnochslaktskap.artfakta.se/), [AlgaeBase](https://www.algaebase.org/), [GBIF](www.gbif.org/), [NORCCA](https://norcca.scrol.net/) in order to update the [species content](https://github.com/nordicmicroalgae/content/tree/master/species) of Nordic Microalgae. In order to run the full update, additional repos from [https://github.com/nordicmicroalgae](https://github.com/nordicmicroalgae) are required and placed in the directory structure outlined below. 

The R package [SHARK4R](https://github.com/sharksmhi/SHARK4R/) is required for some API queries. API queries towards AlgaeBase are based on functions from the [algaeClassify](https://github.com/cran/algaeClassify) package (Patil et al. 2023). Store your API keys to Dyntaxa and AlgaeBase in update-nua-taxonomy/.Renviron.

### References
Patil, V.P., Seltmann, T., Salmaso, N., Anneville, O., Lajeunesse, M., Straile, D., 2023. algaeClassify (ver 2.0.1, October 2023): U.S. Geological Survey software release, https://doi.org/10.5066/F7S46Q3F

## To update the content:
* Clone this repo and other required repos, and place in the directory structure as outlined below.
* Manually download the latest NOMP biovolume list and store in update-nua-taxonomy/data_in/. The file can be accessed from the [Nordic Microalgae webpage](http://nordicmicroalgae.org/tools)
* Manually download the latest IOC HAB list in .txt from this [link](https://www.marinespecies.org/hab/aphia.php?p=download&what=taxlist) and store in update-nua-taxonomy/data_in/
* Run update-nua-taxonomy.Rmd
* Check output for potential duplicated taxa or errors
  * Taxa may be filtered using update-nua-taxonomy/data_in/blacklist.txt and update-nua-taxonomy/data_in/whitelist.txt
* Push updated lists from data_out/content to https://github.com/nordicmicroalgae/content/

Remember to check images with taxon = 'none' in the admin tool after importing new taxa lists, and assign them to their new names.

## Required:

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
   ├─ code/
   │  └─ fun/
   ├─ data_in/
   ├─ data_out/
   │  └─ content/
   └─ update_history/
```
