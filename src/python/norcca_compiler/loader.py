import requests

from .html import StrainsPage


class StrainsLoader:

    base_url = 'https://norcca.scrol.net'

    start_page_number = 0

    def __init__(self):
        self._loaded_page = None

    def load_page(self, page_number=0):
        response = requests.get(
            self.base_url + '/norcca-strains-catalog',
            {'page': max(0, int(page_number))}
        )

        response.raise_for_status()

        self._loaded_page = StrainsPage.from_raw_html(response.text)
        return self._loaded_page

    def load_next_page(self):
        return self.load_page(self.get_next_page_number())

    def get_next_page_number(self):
        if self._loaded_page:
            return self._loaded_page.pager.get_next_page()
        return self.start_page_number

    def has_more(self):
        return self.get_next_page_number() is not None
