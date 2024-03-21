from urllib.parse import parse_qs


class StrainsPager:
    first_item_selector = ('li', {'class': 'pager__item--first'})
    last_item_selector = ('li', {'class': 'pager__item--last'})
    next_item_selector = ('li', {'class': 'pager__item--next'})
    prev_item_selector = ('li', {'class': 'pager__item--previous'})

    def __init__(self, root_node):
        self._root_node = root_node

    def get_first_page(self):
        return self._parse_page_from_node(self._first_pager_item)

    def get_last_page(self):
        return self._parse_page_from_node(self._last_pager_item)

    def get_next_page(self):
        return self._parse_page_from_node(self._next_pager_item)

    def get_prev_page(self):
        return self._parse_page_from_node(self._prev_pager_item)

    def _parse_page_from_node(self, pager_item_node):
        if pager_item_node is None:
            return None

        link_node = pager_item_node.find('a')

        if link_node is None:
            return None

        _, link_qs = link_node.get('href').split('?', maxsplit=1)

        link_params = parse_qs(link_qs)

        return int(link_params['page'][0])

    @property
    def _first_pager_item(self):
        return self._root_node.find(*self.first_item_selector)

    @property
    def _last_pager_item(self):
        return self._root_node.find(*self.last_item_selector)

    @property
    def _next_pager_item(self):
        return self._root_node.find(*self.next_item_selector)

    @property
    def _prev_pager_item(self):
        return self._root_node.find(*self.prev_item_selector)
