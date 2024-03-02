# Repo for updating content/species

## Required:

https://github.com/nordicmicroalgae/taxa-worms

https://github.com/nordicmicroalgae/norcca_compiler

## Directory structure
```
/
├─ norcca_compiler/
│  └─ norcca_compiler/
│     └─ norcca_compiler/
│        ├─ __main__.py
│        ├─ __init__.py
│        ├─ cli.py
│        ├─ compiler.py
│        └─ loader.py
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
   │  ├─ 01_update_used_aphia_id_list.R
   │  ├─ 02_get_worms_synonyms.R
   │  ├─ 03_match_worms_and_dyntaxa.R
   │  ├─ 04_export_algaebase.R
   │  ├─ 05_wrangle_norcca.R
   │  └─ 06_wrangle_hab.R
   ├─ data_out/
   │  └─ content/
   ├─ data_in/
   └─ update-nua-taxonomy.Rmd
```
