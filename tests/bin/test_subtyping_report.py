import sys
from pathlib import Path

import polars as pl
import pandas as pd

# Polars >= 0.20 removed the enable_string_cache argument used by subtyping_report.py
if hasattr(pl, "enable_string_cache"):
    _orig_enable_string_cache = pl.enable_string_cache

    def _enable_string_cache_compat(*args, **kwargs):
        try:
            return _orig_enable_string_cache(*args, **kwargs)
        except TypeError:
            return _orig_enable_string_cache()

    pl.enable_string_cache = _enable_string_cache_compat

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bin"))

from subtyping_report import (  # noqa: E402
    H_COLUMNS,
    N_COLUMNS,
    SUBTYPE_RESULTS_SUMMARY_COLUMNS,
    find_h_or_n_type,
    get_segment_names,
    top_genus,
)


def _make_genus_df(rows: list[dict]) -> pl.DataFrame:
    return pl.DataFrame(rows).with_columns(
        pl.col("sample_segment").cast(pl.Categorical),
        pl.col("Genus").cast(pl.Categorical),
        pl.col("bitscore").cast(pl.Float32),
    )


def test_top_genus_ibv_with_iav_contamination():
    rows = []
    for seg in [1, 2, 5, 7, 8]:
        rows.append(
            {
                "sample_segment": str(seg),
                "Genus": "Betainfluenzavirus",
                "bitscore": 100.0,
            }
        )
    for _ in range(50):
        rows.append(
            {
                "sample_segment": "3",
                "Genus": "Alphainfluenzavirus",
                "bitscore": 500.0,
            }
        )
    assert top_genus(_make_genus_df(rows)) == "Betainfluenzavirus"


def test_top_genus_pure_iav():
    rows = [
        {"sample_segment": str(seg), "Genus": "Alphainfluenzavirus", "bitscore": 200.0}
        for seg in range(1, 9)
    ]
    assert top_genus(_make_genus_df(rows)) == "Alphainfluenzavirus"


def test_find_h_or_n_type_returns_na_columns_when_segment_missing():
    df_merge = pl.DataFrame(
        {
            "sample_segment": ["1"],
            "Genotype": [""],
            "qaccver": ["sample_1"],
            "pident": [95.0],
            "length": [500],
            "mismatch": [0],
            "gapopen": [0],
            "bitscore": [400.0],
            "qlen": [1500],
            "#Accession": ["IBV001"],
            "Host": ["Homo sapiens"],
            "Geo_Location": ["Canada"],
            "Collection_Date": ["2020"],
            "slen": [1500],
            "GenBank_Title": ["Influenza B virus segment 1"],
        }
    ).with_columns(pl.col("sample_segment").cast(pl.Categorical))

    h_result = find_h_or_n_type(df_merge, "4", is_iav=False)
    n_result = find_h_or_n_type(df_merge, "6", is_iav=False)

    for key in H_COLUMNS:
        if key in ("sample", "Genotype"):
            continue
        assert key in h_result
        assert h_result[key] == "N/A"
    for key in N_COLUMNS:
        if key in ("sample", "Genotype"):
            continue
        assert key in n_result
        assert n_result[key] == "N/A"


def test_report_reindex_avoids_keyerror():
    all_subtype_results = {
        "sample_a": {
            "sample": "sample_a",
            "Genotype": "N/A",
        }
    }
    all_cols = list(
        dict.fromkeys(SUBTYPE_RESULTS_SUMMARY_COLUMNS + H_COLUMNS + N_COLUMNS)
    )
    df_subtype_results = pd.DataFrame(all_subtype_results).transpose()
    df_subtype_results = df_subtype_results.reindex(columns=all_cols, fill_value="N/A")
    df_subtype_predictions = df_subtype_results[SUBTYPE_RESULTS_SUMMARY_COLUMNS]
    assert list(df_subtype_predictions.columns) == SUBTYPE_RESULTS_SUMMARY_COLUMNS


def test_ibv_segment_names_after_contamination_genus_vote():
    genus = "Betainfluenzavirus"
    segment_names = get_segment_names(genus)
    assert segment_names[1] == "1_PB1"
    assert segment_names[2] == "2_PB2"
