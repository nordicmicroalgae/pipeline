#!/usr/bin/env python3
# -*- coding:utf-8 -*-
#
# Copyright (c) 2021-present SMHI, Swedish Meteorological and Hydrological Institute
# License: MIT License (see LICENSE.txt or http://opensource.org/licenses/mit).

import pathlib

from wormsextractor import worms_rest_client


class TaxaListGenerator:
    """
    For usage instructions check "https://github.com/sharkdata/species".
    """

    def __init__(
        self,
        data_in_dir="data_in",
        data_out_dir="data_out",
    ):
        """ """
        self.data_in_dir = data_in_dir
        self.data_out_dir = data_out_dir
        self.clear()
        # Create client for the REST API.
        self.worms_client = worms_rest_client.WormsRestClient()
        #
        self.define_out_headers()

    def clear(self):
        """ """
        # Indata:
        # self.indata_name_list = []
        self.indata_aphia_id_list = []

        # Special code for species in "quarantine".
        self.indata_dict_list = {}

        # Outdata.
        self.taxa_worms_header = {}
        self.taxa_worms_dict = {}  # Key: AphiaID.
        self.errors_list = []  # Errors.
        # Working area.
        self.new_aphia_id_list = []
        self.higher_taxa_dict = {}  # Key: aphia_id.

        self.rename_worms_header_items = {
            "AphiaID": "aphia_id",
            "valid_AphiaID": "valid_aphia_id",
            "scientificname": "scientific_name",
        }

    def define_out_headers(self):
        """ """
        self.rename_worms_header_items = {
            "AphiaID": "aphia_id",
            "valid_AphiaID": "valid_aphia_id",
            "scientificname": "scientific_name",
        }

        self.taxa_worms_header = [
            "scientific_name",
            "authority",
            "rank",
            "aphia_id",
            "url",
            "parent_name",
            "parent_id",
            "status",
            "valid_aphia_id",
            "valid_name",
            "valid_authority",
            "kingdom",
            "phylum",
            "class",
            "order",
            "family",
            "genus",
            "classification",
            #             "isBrackish",
            #             "isExtinct",
            #             "isFreshwater",
            #             "isMarine",
            #             "isTerrestrial",
            #             "unacceptreason",
            #             "citation",
            #             "url",
            #             "lsid",
            #             "match_type",
            #             "modified",
        ]

    def run_all(self):
        """ """
        print("\nSpecies list generator started.")

        self.read_indata_files()

        self.prepare_list_of_taxa()

        self.check_taxa_in_worms()
        self.save_results()

        self.add_higher_taxa()
        self.save_results()

        self.add_parent_info()
        self.save_results()

        self.add_classification()

        self.save_results()

        print("\nDone...")

    def read_indata_files(self):
        """
        Imports list containing aphia_id.
        """
        self.import_taxa_by_aphia_id()

    def prepare_list_of_taxa(self):
        """Prepares a list of all aphia ids to import."""
        self.new_aphia_id_list = []

        # Check AphiaID indata list.
        for aphia_id in self.indata_aphia_id_list:
            if str(aphia_id) not in self.new_aphia_id_list:
                print("Load AphiaID: ", aphia_id)
                self.new_aphia_id_list.append(str(aphia_id))

    def check_taxa_in_worms(self):
        """ """
        # Iterate over taxa.
        number_of_taxa = len(self.new_aphia_id_list)
        for index, aphia_id in enumerate(sorted(self.new_aphia_id_list)):
            try:
                worms_rec, error = self.worms_client.get_record_by_aphiaid(aphia_id)
                if error:
                    self.errors_list.append(["", aphia_id, error])
                else:
                    # Replace 'None' by space.
                    for key in worms_rec.keys():
                        if worms_rec[key] in ["None", None]:
                            worms_rec[key] = ""
                    # Translate keys from WoRMS.
                    for from_key, to_key in self.rename_worms_header_items.items():
                        worms_rec[to_key] = worms_rec.get(from_key, "")
                    #
                    aphia_id = worms_rec.get("AphiaID", "")
                    scientific_name = worms_rec.get("scientificname", "")
                    valid_aphia_id = worms_rec.get("valid_AphiaID", "")
                    valid_name = worms_rec.get("valid_name", "")

                    print(
                        "Processing",
                        (index + 1),
                        "of",
                        number_of_taxa,
                        ": ",
                        scientific_name,
                    )

                    self.taxa_worms_dict[aphia_id] = worms_rec
                    # Create classification dictionary.
                    (
                        worms_rec,
                        error,
                    ) = self.worms_client.get_classification_by_aphiaid(aphia_id)
                    if error:
                        self.errors_list.append(["", aphia_id, error])

                    # Replace 'None' by space.
                    for key in worms_rec.keys():
                        if worms_rec[key] in ["None", None]:
                            worms_rec[key] = ""
                    # Translate keys from WoRMS.
                    for from_key, to_key in self.rename_worms_header_items.items():
                        worms_rec[to_key] = worms_rec.get(from_key, "")
                    #
                    aphia_id = None
                    rank = None
                    scientific_name = None
                    current_node = worms_rec
                    while current_node not in [None, ""]:
                        parent_id = aphia_id
                        #                             parent_rank = rank
                        parent_name = scientific_name
                        aphia_id = current_node.get("AphiaID", "")
                        rank = current_node.get("rank", "")
                        scientific_name = current_node.get("scientificname", "")
                        if aphia_id and rank and scientific_name:
                            taxa_dict = {}
                            taxa_dict["aphia_id"] = aphia_id
                            taxa_dict["rank"] = rank
                            taxa_dict["scientific_name"] = scientific_name
                            taxa_dict["parent_id"] = parent_id
                            taxa_dict["parent_name"] = parent_name
                            # Replace 'None' by space.
                            for key in taxa_dict.keys():
                                if taxa_dict[key] in ["None", None]:
                                    taxa_dict[key] = ""
                            if aphia_id not in self.higher_taxa_dict:
                                self.higher_taxa_dict[aphia_id] = taxa_dict
                            current_node = current_node.get("child", None)
                        else:
                            current_node = None
            except Exception as e:
                print("Exception in check_taxa_in_worms: ", e)

    def add_higher_taxa(self):
        """Add higher taxa to WoRMS dictionary."""
        for aphia_id, worms_dict in self.higher_taxa_dict.items():
            scientific_name = worms_dict.get("scientific_name", "")
            if aphia_id not in self.taxa_worms_dict:

                print(
                    "- Processing higher taxa: ", scientific_name, " (", aphia_id, ")"
                )

                worms_rec, error = self.worms_client.get_record_by_aphiaid(aphia_id)
                if error:
                    self.errors_list.append(["", aphia_id, error])
                # Replace 'None' by space.
                for key in worms_rec.keys():
                    if worms_rec[key] in ["None", None]:
                        worms_rec[key] = ""
                # Translate keys from WoRMS.
                for from_key, to_key in self.rename_worms_header_items.items():
                    worms_rec[to_key] = worms_rec.get(from_key, "")
                #
                self.taxa_worms_dict[aphia_id] = worms_rec

    def add_parent_info(self):
        """Add parent info to built classification hierarchies."""
        for taxa_dict in self.taxa_worms_dict.values():
            aphia_id = taxa_dict.get("AphiaID", "")
            higher_taxa_dict = self.higher_taxa_dict.get(aphia_id, None)
            if higher_taxa_dict:
                taxa_dict["parent_id"] = higher_taxa_dict.get("parent_id", "")
                taxa_dict["parent_name"] = higher_taxa_dict.get("parent_name", "")

    def add_classification(self):
        """Add classification."""
        for aphia_id in list(self.taxa_worms_dict.keys()):
            classification_list = []
            taxon_dict = self.taxa_worms_dict[aphia_id]
            name = taxon_dict["scientific_name"]
            level_counter = 0  # To avoid recursive endless loops.
            while len(name) > 0:
                if level_counter > 20:
                    print(
                        "Warning: Too many levels in classification for: "
                        + scientific_name
                    )
                    break
                level_counter += 1
                classification_list.append(
                    "["
                    + taxon_dict.get("rank", "")
                    + "] "
                    + taxon_dict.get("scientific_name", "")
                )
                # Parents.
                parent_id = taxon_dict.get("parent_id", "")
                taxon_dict = self.taxa_worms_dict.get(parent_id, None)
                if taxon_dict:
                    name = taxon_dict.get("scientific_name", "")
                else:
                    name = ""
            # Add classification string.
            self.taxa_worms_dict[aphia_id]["classification"] = " - ".join(
                classification_list[::-1]
            )

    def save_results(self):
        """Save the results"""
        # Create data_out if not exists.
        data_out_path = pathlib.Path(self.data_out_dir)
        if not data_out_path.exists():
            data_out_path.mkdir()
        #
        self.save_errors()
        self.save_taxa_worms()

    def import_taxa_by_aphia_id(self):
        """ """
        indata_aphia_id = pathlib.Path(self.data_in_dir, "used_aphia_id_list.txt")
        if indata_aphia_id.exists():
            print("Importing file: ", indata_aphia_id)
            with indata_aphia_id.open(
                "r", encoding="cp1252", errors="ignore"
            ) as indata_file:
                header = None
                for row in indata_file:
                    row = [item.strip() for item in row.strip().split("\t")]
                    if row:
                        if header is None:
                            header = row
                        else:
                            row_dict = dict(zip(header, row))
                            aphia_id = row_dict.get("used_aphia_id", "")
                            if aphia_id:
                                # Avoid duplicates.
                                if aphia_id not in self.indata_aphia_id_list:
                                    self.indata_aphia_id_list.append(aphia_id)

                                # Special code for species in "quarantine".
                                self.indata_dict_list[aphia_id] = row_dict

            print("")

    def save_taxa_worms(self):
        """ """
        taxa_worms_file = pathlib.Path(self.data_out_dir, "taxa_worms.txt")
        with taxa_worms_file.open(
            "w", encoding="cp1252", errors="ignore"
        ) as outdata_file:
            outdata_file.write("\t".join(self.taxa_worms_header) + "\n")
            for taxa_dict in self.taxa_worms_dict.values():
                row = []

                # Special code for species in "quarantine".
                aphia_id = taxa_dict.get("aphia_id", "")
                indata_dict = self.indata_dict_list.get(str(aphia_id), False)
                if indata_dict:
                    if not taxa_dict["scientific_name"]:
                        taxa_dict["scientific_name"] = indata_dict.get(
                            "used_scientific_name", ""
                        )
                    if not taxa_dict["authority"]:
                        taxa_dict["authority"] = indata_dict.get("used_authority", "")
                    if not taxa_dict["rank"]:
                        taxa_dict["rank"] = indata_dict.get("used_rank", "")

                for header_item in self.taxa_worms_header:
                    row.append(str(taxa_dict.get(header_item, "")))
                try:
                    outdata_file.write("\t".join(row) + "\n")
                except Exception as e:
                    try:
                        print(
                            "Exception when writing to taxa_worms.txt: ",
                            row[0],
                            "   ",
                            e,
                        )
                    except:
                        pass

    def save_errors(self):
        """ """
        header = ["scientific_name", "aphia_id", "error"]
        errors_file = pathlib.Path(self.data_out_dir, "errors.txt")
        with errors_file.open("w", encoding="cp1252", errors="ignore") as outdata_file:
            outdata_file.write("\t".join(header) + "\n")
            for row in self.errors_list:
                try:
                    outdata_file.write("\t".join(row) + "\n")
                except Exception as e:
                    try:
                        print(
                            "Exception when writing to taxa_worms.txt: ",
                            row[0],
                            "   ",
                            e,
                        )
                    except:
                        pass
