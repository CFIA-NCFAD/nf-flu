/*
Module for running nextflow: ripping this off from the nf-core modules but the other modules are too out of date
to update them without other larger changes being required

*/


process NEXTCLADE_RUN{

    tag "Nextclade"
    label 'process_low'


    conda (params.enable_conda ? "bioconda::nextclade=2.12.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nextclade:2.12.0--h9ee0642_0' :
        'quay.io/biocontainers/nextclade:2.12.0--h9ee0642_0' }"


    input:
    path consensus_fastas
    path dataset

    output:
    path("nextclade.csv"), optional:true, emit: csv
    path("nextclade.errors.csv"), optional:true, emit: csv_errors
    path("nextclade.insertions.csv"), optional:true, emit: csv_insertions
    path("nextclade.tsv"), optional:true, emit: tsv
    path("nextclade.json"), optional:true, emit: json
    path("nextclade.auspice.json"), optional:true, emit: json_auspice
    path("nextclade.ndjson"), optional:true, emit: ndjson
    path("nextclade.aligned.fasta"), optional:true, emit: fasta_aligned
    path("nextclade.translation.fasta"), optional:true, emit: fasta_translation
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    """
    cat $consensus_fastas > combined_fastas.fa
    nextclade run $args --jobs $task.cpus --input-dataset $dataset --output-all ./ combined_fastas.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextclade: \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """

}



process NEXTCLADE_DATASETGET {
    tag "Nextclade"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::nextclade=2.12.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nextclade:2.12.0--h9ee0642_0' :
        'quay.io/biocontainers/nextclade:2.12.0--h9ee0642_0' }"

    input:
    val dataset
    val reference
    val tag

    output:
    path "$prefix", emit: dataset
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${dataset}"
    def fasta = reference ? "--reference ${reference}" : ''
    def version = tag ? "--tag ${tag}" : ''
    """
    nextclade dataset get $args --name $dataset $fasta $version --output-dir $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextclade: \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """
}