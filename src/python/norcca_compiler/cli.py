import argparse
import csv
import sys


from norcca_compiler import StrainsCompiler


class CompileCommand:
    def get_argument_parser(self):
        parser = argparse.ArgumentParser(
            description=(
                'Compile a list of strains '
                'available on the NORCCA website'
            )
        )
        parser.add_argument(
            '-O',
            '--output',
            dest='target',
            help='path to output file',
        )
        return parser

    def run(self):
        args = self.get_argument_parser().parse_args()

        try:
            if args.target is None:
                output = sys.stdout
            else:
                output = open(
                    args.target,
                    mode='w',
                    encoding='utf8',
                    newline=''
                )

            compiler = StrainsCompiler()
            compiler.compile()

            csv_writer = csv.DictWriter(
                output, 
                fieldnames=compiler.headers,
                dialect='excel-tab',
            )
            csv_writer.writeheader()
            csv_writer.writerows(compiler.rows)

        finally:
            if output and output != sys.stdout:
                output.close()
