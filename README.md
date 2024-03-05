# Repo for updating Nordic Microalgae content/species

The R Markdown document update-nua-taxonomy.Rmd calls a number of R and Python scripts to interact with APIs and webpages from [WoRMS](https://www.marinespecies.org/), [Dyntaxa](https://namnochslaktskap.artfakta.se/), [AlgaeBase](https://www.algaebase.org/), [NORCCA](https://norcca.scrol.net/) in order to update the [species content](https://github.com/nordicmicroalgae/content/tree/master/species) of Nordic Microalgae. In order to run the full update, additional repos from https://github.com/nordicmicroalgae are required and placed in the directory structure outlined below. The R package [SHARK4R](https://github.com/sharksmhi/SHARK4R/
) is required for some API queries.

## To update the content:
* Clone the repo and the other required repos, and place in the directory structure as outlined below.
* Manually download the latest NOMP biovolume list and store in update-nua-taxonomy/data_in/. The file can be accessed from the [Nordic Microalgae webpage](http://nordicmicroalgae.org/tools)
* Manually download the latest IOC HAB list in .txt from this [link](https://www.marinespecies.org/hab/aphia.php?p=download&what=taxlist) and store in update-nua-taxonomy/data_in/
* Run update-nua-taxonomy.Rmd
* Check output for potential duplicated taxa or errors
* Send the AlgaeBase lists to the AlgaeBase team for updated links
* Push updated lists from /data_out/content to https://github.com/nordicmicroalgae/content/

## Required:

https://github.com/nordicmicroalgae/taxa-worms

https://github.com/nordicmicroalgae/norcca_compiler

## Directory structure
```
/
├─ norcca_compiler/
│  └─ norcca_compiler/
│     ├─ __main__.py
│     ├─ __init__.py
│     ├─ cli.py
│     ├─ compiler.py
│     └─ loader.py
├─ taxa_worms/
│  ├─ data_in/
│  ├─ data_out/
│  ├─ wormsextractor/
│  │  ├─ __init__.py
│  │  ├─ worms_extract_taxa.py
│  │  ├─ worms_rest_client.py
│  │  └─ worms_sqlite_cache.py
│  └─ extract_from_worms_main.py
└─ update-nua-taxonomy/
   ├─ code/
   │  ├─ 01_get_current_aphia_ids.R
   │  ├─ 02_get_worms_synonyms.R
   │  ├─ 03_match_dyntaxa.R
   │  ├─ 04_export_algaebase.R
   │  ├─ 05_wrangle_norcca.R
   │  └─ 06_wrangle_hab.R
   ├─ data_in/
   ├─ data_out/
   │  └─ content/
   ├─ update_history/
   └─ update-nua-taxonomy.Rmd
```
