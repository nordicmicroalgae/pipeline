from bs4 import BeautifulSoup

from .table import StrainsTable
from .pager import StrainsPager


class StrainsPage:

    table_selector = ('table',)

    pager_selector = ('ul', {'class': 'pager__items'})

    def __init__(self, root_node):
        self._root_node = root_node

        self._table = StrainsTable(
            self._root_node.find(*self.table_selector)
        )

        self._pager = StrainsPager(
            self._root_node.find(*self.pager_selector)
        )

    @property
    def table(self):
        return self._table

    @property
    def pager(self):
        return self._pager

    @classmethod
    def from_raw_html(cls, raw_html_text):
        return cls(
            BeautifulSoup(raw_html_text, features='html.parser')
        )
