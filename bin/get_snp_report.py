#!/usr/bin/env python

from typing import List, Tuple
import json
import logging
import click
import pandas as pd
import numpy as np
import re

influenza_segment = {
    1: "1_PB2",
    2: "2_PB1",
    3: "3_PA",
    4: "4_HA",
    5: "5_NP",
    6: "6_NA",
    7: "7_M",
    8: "8_NS",
}

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
# Regex to find unallowed characters in Excel worksheet names
REGEX_UNALLOWED_EXCEL_WS_CHARS = re.compile(r"[\\:/?*\[\]]+")

@click.command()
@click.option("-x", "--excel-report", default="snp_report.xlsx", help="Excel report")
@click.option("-j", "--json_path", default="", help="Blast Result.")
def main(excel_report,json_path):
    res = []
    with open(json_path, "r") as json_file:
        contents = json.load(json_file)
        for content in contents:
            res.append(content)
    df = pd.DataFrame(res)[[x for x, y in edlib_columns]]
    df["reference"] = df["reference"].str.extract('(.+?)_[sS]egment')
    df = df.astype({x:y for x, y in edlib_columns})
    df.sort_values(['sample','segment'], inplace=True)
    df["sample"] = df["sample"].str.extract('(.+?).[1-9]_')
    segments = df["segment"].unique()
    ref_names = df["reference"].unique()
    df_mismatch_report = pd.DataFrame(index=segments, columns=ref_names)
    df_indel_report = pd.DataFrame(index=segments, columns=ref_names)
    df_editdistance_report = pd.DataFrame(index=segments, columns=ref_names)
    for segment in segments:
        for ref_name in ref_names:
            mismatch = df.query("reference == @ref_name and segment == @segment")["mismatches"].values
            indel = df.query("reference == @ref_name and segment == @segment")["indels"].values
            edit_distance = df.query("reference == @ref_name and segment == @segment")["editDistance"].values
            # mismatch
            if len(mismatch):
                df_mismatch_report.loc[segment, ref_name] = mismatch[0]
            else:
                df_mismatch_report.loc[segment, ref_name] = ''
            #indel
            if len(indel):
                df_indel_report.loc[segment, ref_name] = indel[0]
            else:
                df_indel_report.loc[segment, ref_name] = ''
            #edit distance
            if len(edit_distance):
                df_editdistance_report.loc[segment, ref_name] = edit_distance[0]
            else:
                df_editdistance_report.loc[segment, ref_name] = ''
    df_mismatch_report.insert(0, "Segment", segments)
    df_indel_report.insert(0, "Segment", segments)
    df_editdistance_report.insert(0, "Segment", segments)
    df_mismatch_report.loc["Total"] = pd.Series(df_mismatch_report[ref_names].sum())
    df_indel_report.loc["Total"] = pd.Series(df_indel_report[ref_names].sum())
    df_editdistance_report.loc["Total"] = pd.Series(df_editdistance_report[ref_names].sum())

    write_excel(
        [
            ("EDLIB_Report", df),
            ("Mismatches", df_mismatch_report),
            ("Indels", df_indel_report),
            ("EditDistance", df_editdistance_report),
        ],
        output_dest=excel_report,
    )

def get_col_widths(df, index=False):
    """Calculate column widths based on column headers and contents"""
    if index:
        idx_max = max(
            [len(str(s)) for s in df.index.values] + [len(str(df.index.name))]
        )
        yield idx_max
    for c in df.columns:
        # get max length of column contents and length of column header
        yield np.max([df[c].astype(str).str.len().max() + 1, len(c) + 1])


def write_excel(
        name_dfs: List[Tuple[str, pd.DataFrame]],
        output_dest: str,
        sheet_name_index: bool = True,
) -> None:
    logging.info("Starting to write tabular data to worksheets in Excel workbook")
    with pd.ExcelWriter(output_dest, engine="xlsxwriter") as writer:
        idx = 1
        for name_df in name_dfs:
            if not isinstance(name_df, (list, tuple)):
                logging.error(
                    'Input "%s" is not a list or tuple (type="%s"). Skipping...',
                    name_df,
                    type(name_df),
                )
                continue
            sheetname, df = name_df
            fixed_sheetname = REGEX_UNALLOWED_EXCEL_WS_CHARS.sub("_", sheetname)
            # fixed max number of characters in sheet name due to compatibility
            if sheet_name_index:
                max_chars = 28
                fixed_sheetname = "{}_{}".format(idx, fixed_sheetname[:max_chars])
            else:
                max_chars = 31
                fixed_sheetname = fixed_sheetname[:max_chars]

            if len(fixed_sheetname) > max_chars:
                logging.warning(
                    'Sheetname "%s" is >= %s characters so may be truncated (n=%s)',
                    max_chars,
                    fixed_sheetname,
                    len(fixed_sheetname),
                )

            logging.info('Writing table to Excel sheet "{}"'.format(fixed_sheetname))
            df.to_excel(
                writer, sheet_name=fixed_sheetname, index=False, freeze_panes=(1, 1)
            )
            worksheet = writer.book.get_worksheet_by_name(fixed_sheetname)
            for i, width in enumerate(get_col_widths(df, index=False)):
                worksheet.set_column(i, i, width)
            idx += 1
    logging.info('Done writing worksheets to spreadsheet "%s".', output_dest)

if __name__ == '__main__':
    main()
