#!/usr/bin/env python3
# -*- coding:utf-8 -*-
#
# Copyright (c) 2021-present SMHI, Swedish Meteorological and Hydrological Institute
# License: MIT License (see LICENSE.txt or http://opensource.org/licenses/mit).

import pathlib
import sqlite3
import json


class WormsSqliteCache:
    """ """

    def __init__(self, db_file="cache/worms_cache.db"):
        """ """
        self.db_file = db_file
        self.db_path = pathlib.Path(self.db_file)
        self.db_conn = None

    def createDb(self):
        """ """
        if not self.db_path.exists():
            self.db_conn = sqlite3.connect(self.db_path)
            c = self.db_conn.cursor()
            c.execute(
                "CREATE TABLE worms_records(aphia_id varchar(20) PRIMARY KEY, data json)"
            )
            c.execute(
                "CREATE TABLE classification(aphia_id varchar(20) PRIMARY KEY, data json)"
            )
            self.db_conn.commit()

    def connect(self):
        """ """
        self.createDb()
        if self.db_conn == None:
            self.db_conn = sqlite3.connect(self.db_path)

    def add_worms_record(self, aphia_id, data_json):
        """ """
        if len(data_json) == 0:
            print("Error: Empty record to cache, record: ", aphia_id)
            return
        self.connect()
        try:
            c = self.db_conn.cursor()
            c.execute(
                "insert into worms_records values (?, ?)",
                (
                    aphia_id,
                    json.dumps(
                        data_json,
                    ),
                ),
            )
            self.db_conn.commit()
        finally:
            c.close()

    def get_worms_record(self, aphia_id):
        """ """
        self.connect()
        try:
            c = self.db_conn.cursor()
            c.execute("select data from worms_records where aphia_id = ?", (aphia_id,))
            result_dict = c.fetchone()
            # print(result_dict)
            result_dict = json.loads(result_dict[0])
            return result_dict
        finally:
            c.close()

    def contains_worms_record(self, aphia_id):
        """ """
        self.connect()
        try:
            c = self.db_conn.cursor()
            c.execute(
                "select 1 from worms_records where aphia_id = ? limit 1", (aphia_id,)
            )
            result = c.fetchone()
            if result and (len(result) > 0):
                return True
            else:
                return False
        finally:
            c.close()

    def add_classification(self, aphia_id, data_json):
        """ """
        if len(data_json) == 0:
            print("Error: Empty record to cache, classification: ", aphia_id)
            return
        self.connect()
        try:
            c = self.db_conn.cursor()
            data_json["aphiaId"] = aphia_id
            c.execute(
                "insert into classification values (?, ?)",
                (
                    aphia_id,
                    json.dumps(
                        data_json,
                    ),
                ),
            )
            self.db_conn.commit()
        finally:
            c.close()

    def get_classification(self, aphia_id):
        """ """
        self.connect()
        try:
            c = self.db_conn.cursor()
            c.execute("select data from classification where aphia_id = ?", (aphia_id,))
            result_dict = c.fetchone()
            # print(result_dict)
            result_dict = json.loads(result_dict[0])
            return result_dict
        finally:
            c.close()

    def contains_classification(self, aphia_id):
        """ """
        self.connect()
        try:
            c = self.db_conn.cursor()
            c.execute(
                "select 1 from classification where aphia_id = ? limit 1", (aphia_id,)
            )
            result = c.fetchone()
            if result and (len(result) > 0):
                return True
            else:
                return False
        finally:
            c.close()
