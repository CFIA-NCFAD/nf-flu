#!/usr/bin/env python

import json

import click
import pandas as pd

edlib_columns = [
    ('sample', str),
    ('segment', str),
    ('reference', str),
    ('editDistance', int),
    ('identity', str),
    ('matches', int),
    ('mismatches', int),
    ('indels', int),
    ('locations', object),
    ('consensus_n_chars', int),
    ('reference_n_chars', int),
    ]

table_front_matter = """# plot_type: 'table'
# section_name: 'Edlib Global Pairwise Alignment'
# section_href: 'https://github.com/Martinsos/edlib'
# description: 'Global pairwise alignment of consensus sequences against user sequences using Edlib.'
# pconfig:
#     namespace: 'Edlib'
# headers:
#     sample:
#         title: 'Sample'
#         description: 'Sample name'
#         format: '{}'
#     segment:
#         title: 'Segment'
#         description: 'Segment name'
#         format: '{}'
#     reference:
#         title: 'Reference'
#         description: 'Reference sequence ID'
#         scale: False
#         format: '{}'
#     editDistance:
#         title: 'Edit Distance'
#         description: 'Edlib edit (Levenshtein) distance'
#         format: '{:.0f}'
#     identity:
#         title: 'Identity'
#         description: 'Mash screen identity'
#         format: '{:.1%}'
#     matches:
#         title: 'Matches'
#         description: 'Edlib alignment matching positions'
#         format: '{:.0f}'
#     mismatches:
#         title: 'Mismatches'
#         description: 'Edlib alignment mismatching positions'
#         format: '{:.0f}'
#     indels:
#         title: 'Indels'
#         description: 'Edlib alignment indel positions'
#         format: '{:.0f}'
#     locations:
#         title: 'Locations'
#         description: 'Edlib alignment locations'
#         scale: False
#         format: '{}'
#     consensus_n_chars:
#         title: 'Ns Sample'
#         description: 'Number of Ns in sample consensus sequence'
#         format: '{:.0f}'
#     reference_n_chars:
#         title: 'Ns Ref'
#         description: 'Number of Ns in reference sequence'
#         format: '{:.0f}'
"""


@click.command()
@click.argument('mqc_summary_output', type=click.Path(exists=False))
@click.argument("json_paths", nargs=-1)
def main(mqc_summary_output,
         json_paths):
    """Summarize Edlib pairwise alignment results for MultiQC"""
    res = []
    for json_path in json_paths:
        with open(json_path, "r") as json_file:
            contents = json.load(json_file)
            for content in contents:
                res.append(content)
    df = pd.DataFrame(res)[[x for x, y in edlib_columns]]
    df = df.astype({x:y for x, y in edlib_columns})
    df.sort_values(['sample','segment'], inplace=True)
    df.set_index('sample', inplace=True)
    with open(mqc_summary_output, 'w') as fout:
        fout.write(table_front_matter)
        df.to_csv(fout, sep='\t', quoting=None)


if __name__ == '__main__':
    main()
