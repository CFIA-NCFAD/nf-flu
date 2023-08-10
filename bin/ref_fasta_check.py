#!/usr/bin/env python

from pathlib import Path
from Bio import SeqIO
import typer
import re
from rich.logging import RichHandler
import logging

def main(input_fasta: Path, output_fasta: Path):
    from rich.traceback import install

    install(show_locals=True, width=120, word_wrap=True)
    logging.basicConfig(
        format="%(message)s",
        datefmt="[%Y-%m-%d %X]",
        level=logging.DEBUG,
        handlers=[RichHandler(rich_tracebacks=True, tracebacks_show_locals=True)],
    )

    logging.info(
        f'input_fasta="{input_fasta}" output_correct_fasta="{output_fasta}"'
    )
    ref_fasta = SeqIO.parse(open(input_fasta), 'fasta')
    with open(output_fasta, 'w') as outfile:
        for rec in ref_fasta:
            seqid, sequence = rec.id, rec.seq
            #replace non-word, non-digit, non-period or dash characters
            new_seqid = re.sub(r'[^\w\-]+', '_', seqid)
            # remove leading and trailing underscores
            new_seqid = re.sub(r'^_|_$', '', new_seqid)
            outfile.write(f'>{new_seqid}\n{sequence.upper()}\n')


if __name__ == "__main__":
    typer.run(main)
