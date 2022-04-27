// Import generic module functions
include { getSoftwareName } from './functions'


process BLAST_BLASTDBCMD{
    tag "$sample_name - Segment:$segment - Ref ID:$id"
    label 'process_low'

    conda (params.enable_conda ? 'bioconda::blast=2.12.0' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/blast:2.12.0--pl5262h3289130_0'
    } else {
        container 'quay.io/biocontainers/blast:2.12.0--pl5262h3289130_0'
    }

    input:
    tuple val(sample_name), val(segment), val(id), path(reads)
    path (db)

    output:
    tuple val(sample_name), val(segment), val(id), path('*.fasta'), path(reads), emit: sample_info
    path "versions.yml"                  , emit: versions

    script:
    def software = getSoftwareName(task.process)
    def prefix   = "${sample_name}"
    """
    DB=`find -L ./ -name "*.ndb" | sed 's/.ndb//'`
    blastdbcmd \\
        -db \$DB \\
        -entry $id\\
        -out ${prefix}.Segment_${segment}.${id}.reference.fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS
    """
}
/* Will use it in next release
process SEQTK{
    tag "$sample_name - Segment:$segment - Ref Accession ID:$id"
    label 'process_medium'
    publishDir "${params.outdir}/reference_sequences/$sample_name",
        pattern: "*.fasta",
        mode: params.publish_dir_mode

    conda (params.enable_conda ? 'bioconda::seqtk=1.3' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/seqtk:1.2--1'
    } else {
        container 'biocontainers/seqtk:v1.3-1-deb_cv1'
    }

    input:
    tuple val(sample_name), val(segment), val(id), path(reads)
    path (fasta)

    output:
    tuple val(sample_name), val(segment), val(id), path('*.fasta'), path(reads), emit: fasta

    script:
    def software = getSoftwareName(task.process)
    def prefix   = "${sample_name}"
    """
    seqtk subseq $fasta $id > ${prefix}.Segment_${segment}.${id}.seqtk_reference.fasta
    """
}
*/

