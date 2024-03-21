from .loader import StrainsLoader


class StrainsCompiler:
    def __init__(self):
        self.reset()
        self._loader = StrainsLoader()

    def reset(self):
        self._found_headers = []
        self._extra_headers = []
        self._rows = []

    def compile(self):
        self.reset()
        self.run_loop()

    def run_loop(self):
        while self._loader.has_more():
            self.on_receive_page(
                self._loader.load_next_page()
            )

    def on_receive_page(self, page):
        if len(self._found_headers) == 0:
            self._found_headers = page.table.get_cols()

        for row in page.table.get_rows():
            row_dict = {}
            for field_index, field in enumerate(row):
                field_name = self._found_headers[field_index]
                field_value, field_link = field

                row_dict[field_name] = field_value

                if field_link:
                    link_header = (
                        '%s Link'
                        % field_name.replace(' name', '')
                    )
                    if link_header not in self._extra_headers:
                        self._extra_headers.append(link_header)

                    if field_link.startswith('/'):
                        field_link = StrainsLoader.base_url + field_link
                    row_dict[link_header] = field_link

            self._rows.append(row_dict)

    @property
    def headers(self):
        return self._found_headers + self._extra_headers

    @property
    def rows(self):
        return self._rows
