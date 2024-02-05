#!/usr/bin/env python

import json
from collections import OrderedDict
import re

import click
import edlib
from Bio import SeqIO


@click.command()
@click.option('--sample', required=True)
@click.option('--consensus', required=True, type=click.Path(exists=True))
@click.option('--reference', required=True, type=click.Path(exists=True))
def main(sample,
         consensus,
         reference):
    """Perform edlib global pairwise alignment of consensus sequence against reference sequence"""
    aln_json_rec = []
    for reccon in SeqIO.parse(consensus, "fasta"):
        reccon_segment_id = re.findall(r'[sS]egment\w+', reccon.id)[0]
        reccon_segment_id = re.sub(r'[sS]egment', '', reccon_segment_id)
        for recref in SeqIO.parse(reference, "fasta"):
            recref_segment_id = re.findall(r'[sS]egment\w+', recref.id)[0]
            recref_segment_id = re.sub(r'[sS]egment', '', recref_segment_id)
            if reccon_segment_id == recref_segment_id: # align the same segment
                conseq = str(reccon.seq).upper()
                con_n_chars = conseq.count('N')
                refseq = str(recref.seq).upper()
                ref_n_chars = refseq.count('N')
                aln = edlib.align(conseq, refseq, task='path')
                nice_aln = edlib.getNiceAlignment(aln, conseq, refseq)
                aln['sample'] = '.'.join([sample, reccon_segment_id, recref.id])
                aln['segment'] = recref_segment_id
                aln['reference'] = recref.id
                aln['consensus_n_chars'] = con_n_chars
                aln['reference_n_chars'] = ref_n_chars
                mismatches = nice_aln['matched_aligned'].count('.')
                matches = nice_aln['matched_aligned'].count('|')
                align_len = len(nice_aln['matched_aligned'])
                indels = align_len - mismatches - matches
                aln['indels'] = indels
                aln['mismatches'] = mismatches
                aln['matches'] = matches
                aln['alignmentLength'] = align_len
                aln['identity'] = f"{matches / len(conseq):.2%}"
                aln_json_rec.append(aln)
                output_file = ".".join([sample, "Segment_"+recref_segment_id, recref.id, "edlib", "txt"])
                with open(output_file, 'w') as fh:
                    write_header(fh, 'Input Attributes')
                    attrs = OrderedDict()
                    attrs['Sample name'] = sample
                    attrs['Segment'] = recref_segment_id
                    attrs['Consensus file'] = consensus
                    attrs['Reference file'] = reference
                    attrs['Consensus seq name'] = reccon.id
                    attrs['Consensus seq length'] = len(conseq)
                    attrs['Consensus seq Ns'] = con_n_chars
                    attrs['Reference seq name'] = recref.id
                    attrs['Reference seq length'] = len(refseq)
                    attrs['Reference seq Ns'] = ref_n_chars
                    max_attr_key_len = max(len(x) for x in attrs.keys())
                    for k, v in attrs.items():
                        fh.write(f'{k}:{" " * (max_attr_key_len - len(k))} {v}\n')

                    write_header(fh, 'Edlib Alignment')
                    aln_keys = ['editDistance', 'alignmentLength', 'matches', 'mismatches', 'indels', 'identity', 'alphabetLength', 'locations', 'cigar']
                    max_aln_key_len = max(len(x) for x in aln_keys)
                    for x in aln_keys:
                        print (aln[x])
                        fh.write(f'{x}:{" " * (max_aln_key_len - len(x))} {aln[x]}\n')
                    write_nice_alignment(nice_aln, fh, recref, sample)

    json_output = '.'.join([sample, "edlib.json"])
    with open(json_output, 'w') as fh_json:
        json.dump(aln_json_rec, fh_json)



def write_nice_alignment(nice_aln, fh, recref, sample):
    write_header(fh, f'Full alignment - {sample} (Query) VS {recref.id} (Target)')
    fh.write('"M" for match where "." denotes a mismatch, "-" denotes a indel and "|" denotes a match\n')
    aln_len = len(nice_aln['query_aligned'])
    line_width = 60
    for i in range(0, aln_len, line_width):
        for key in ['query_aligned', 'matched_aligned', 'target_aligned']:
            fh.write(f'{key[0].upper()} {i + 1: 5} {nice_aln[key][i:i + line_width]}\n')
        fh.write(f'\n')


def write_header(fh, header):
    fh.write('=' * 80 + '\n' + header + '\n' + '=' * 80 + '\n')


if __name__ == '__main__':
    main()
