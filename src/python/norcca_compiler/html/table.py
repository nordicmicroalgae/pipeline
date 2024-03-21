

class StrainsTable:
    thead_selector = ('thead',)
    tbody_selector = ('tbody',)

    def __init__(self, root_node):
        self._root_node = root_node

    def get_cols(self):
        return [
            col.get_text(strip=True) 
            for col in self._thead.find_all('th')
        ]

    def get_rows(self):
        rows = []

        for row_node in self._tbody.find_all('tr'):
            row = []
            for data_node in row_node.find_all('td'):
                link_node = data_node.find('a')
                row.append((
                    data_node.get_text(strip=True),
                    link_node.get('href') if link_node else None
                ))
            rows.append(row)

        return rows

    @property
    def _table(self):
        return self._root_node

    @property
    def _thead(self):
        return self._table.find(*self.thead_selector)

    @property
    def _tbody(self):
        return self._table.find(*self.tbody_selector)
