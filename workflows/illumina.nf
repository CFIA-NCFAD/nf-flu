#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

//=============================================================================
// NCBI Influenza DB reference data
//=============================================================================

ch_influenza_db_fasta = file(params.ncbi_influenza_fasta)
ch_influenza_metadata = file(params.ncbi_influenza_metadata)

//=============================================================================
// MODULES
//=============================================================================

include { IRMA } from '../modules/local/irma'
include { CHECK_SAMPLE_SHEET } from '../modules/local/check_sample_sheet'
include { SUBTYPING_REPORT } from '../modules/local/subtyping_report'
include { GUNZIP_NCBI_FLU_FASTA } from '../modules/local/misc'
include { BLAST_MAKEBLASTDB } from '../modules/local/blast_makeblastdb'
include { BLAST_BLASTN } from '../modules/nf-core/modules/blast/blastn/main'
include { CAT_FASTQ } from '../modules/nf-core/modules/cat/fastq/main'
include { NEXTCLADE_RUN; NEXTCLADE_DATASETGET } from '../modules/local/nextclade'

//=============================================================================
// Workflow Params Setup
//=============================================================================

def irma_module = 'FLU-utr'
if (params.irma_module) {
    irma_module = params.irma_module
}

//=============================================================================
// WORKFLOW
//=============================================================================

workflow ILLUMINA {
  ch_versions = Channel.empty()

  GUNZIP_NCBI_FLU_FASTA(ch_influenza_db_fasta)
  ch_versions = ch_versions.mix(GUNZIP_NCBI_FLU_FASTA.out.versions)

  BLAST_MAKEBLASTDB(GUNZIP_NCBI_FLU_FASTA.out.fna)
  ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions)

  CHECK_SAMPLE_SHEET(Channel.fromPath( params.input, checkIfExists: true))
    .splitCsv(header: ['sample', 'fastq1', 'fastq2', 'single_end'], sep: ',', skip: 1)
    .map {
      def meta = [:]
      meta.id = it.sample
      meta.single_end = it.single_end.toBoolean()
      def reads = []
      def fastq1 = file(it.fastq1)
      def fastq2
      if (!fastq1.exists()) {
        exit 1, "ERROR: Please check input samplesheet. FASTQ file 1 '${fastq1}' does not exist!"
      }
      if (meta.single_end) {
        reads = [fastq1]
      } else {
        fastq2 = file(it.fastq2)
        if (!fastq2.exists()) {
          exit 1, "ERROR: Please check input samplesheet. FASTQ file 2 '${fastq2}' does not exist!"
        }
        reads = [fastq1, fastq2]
      }
      [ meta, reads ]
    } 
    .groupTuple(by: [0]) \
    .branch { meta, reads ->
      single: reads.size() == 1
        return [ meta, reads.flatten() ]
      multiple: reads.size() > 1
        return [ meta, reads.flatten() ]
    }
    .set { ch_input }

  // Credit to nf-core/viralrecon. Source: https://github.com/nf-core/viralrecon/blob/a85d5969f9025409e3618d6c280ef15ce417df65/workflows/illumina.nf#L221
  // Concatenate FastQ files from same sample if required
  CAT_FASTQ(ch_input.multiple)
    .mix(ch_input.single)
    .set { ch_cat_reads }

  IRMA(ch_cat_reads, irma_module)
  ch_versions = ch_versions.mix(IRMA.out.versions)

  BLAST_BLASTN(IRMA.out.consensus, BLAST_MAKEBLASTDB.out.db)
  ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

  if(!params.skip_nextclade){
    // TODO: PK: select dataset for each sample based on subtyping results?
    NEXTCLADE_DATASETGET(
      params.nextclade_dataset,
      params.nextclade_reference,
      params.nextclade_tag
    )
    ch_versions = ch_versions.mix(NEXTCLADE_DATASETGET.out.versions)

    // TODO: PK: prefilter for segments that make sense given Nextclade dataset being used
    ch_consensus_seqs = IRMA.out.consensus.map { it[1] }
    NEXTCLADE_RUN(
      ch_consensus_seqs.collect(),
      NEXTCLADE_DATASETGET.out.dataset
    )
    ch_versions = ch_versions.mix(NEXTCLADE_RUN.out.versions)
  }

  ch_blast = BLAST_BLASTN.out.txt.collect({ it[1] })
  SUBTYPING_REPORT(ch_influenza_metadata, ch_blast)
}
