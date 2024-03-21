#!/usr/bin/env python3
# -*- coding:utf-8 -*-
#
# Copyright (c) 2021-present SMHI, Swedish Meteorological and Hydrological Institute
# License: MIT License (see LICENSE.txt or http://opensource.org/licenses/mit).

import json
import urllib.request

from wormsextractor import worms_sqlite_cache


class WormsRestClient:
    """
    For usage instructions check "https://github.com/sharkdata/species".
    """

    def __init__(self):
        """ """
        self.db_cache = worms_sqlite_cache.WormsSqliteCache()

    def get_record_by_aphiaid(self, aphia_id):
        """WoRMS REST: AphiaRecordByAphiaID"""
        # Check db cache.
        if self.db_cache.contains_worms_record(aphia_id):
            worms_record = self.db_cache.get_worms_record(aphia_id)
            error = ""
            return (worms_record, error)

        # Ask REST API.
        url = "https://www.marinespecies.org/rest/AphiaRecordByAphiaID/" + str(aphia_id)
        result_dict = {}
        error = ""
        try:
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req) as response:
                if response.getcode() == 200:
                    result_dict = json.loads(response.read().decode("utf-8"))
                else:
                    error = (
                        "AphiaID: "
                        + str(aphia_id)
                        + "  Response code: "
                        + str(response.getcode())
                    )
        except Exception as e:
            error = "AphiaID: " + str(aphia_id) + "  Exception: " + str(e)

        # Save to db cache.
        self.db_cache.add_worms_record(aphia_id, result_dict)
        #
        return (result_dict, error)

    def get_classification_by_aphiaid(self, aphia_id):
        """WoRMS REST: AphiaClassificationByAphiaID"""
        # Check db cache.
        if self.db_cache.contains_classification(aphia_id):
            worms_record = self.db_cache.get_classification(aphia_id)
            error = ""
            return (worms_record, error)

        # Ask REST API.
        url = "https://www.marinespecies.org/rest/AphiaClassificationByAphiaID/" + str(
            aphia_id
        )
        result_dict = {}
        error = ""
        try:
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req) as response:
                if response.getcode() == 200:
                    result_dict = json.loads(response.read().decode("utf-8"))
                else:
                    error = (
                        "AphiaID: "
                        + str(aphia_id)
                        + "  Response code: "
                        + str(response.getcode())
                    )
        except Exception as e:
            error = "AphiaID: " + str(aphia_id) + "  Exception: " + str(e)

        # Save to db cache.
        self.db_cache.add_classification(aphia_id, result_dict)
        #
        return (result_dict, error)
