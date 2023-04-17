/*

Adapted from nf-core/modules (https://github.com/nf-core/modules/tree/master/modules/nf-core/nextclade)
*/

process NEXTCLADE_RUN {
    label 'process_low'

    conda (params.enable_conda ? "bioconda::nextclade=2.13.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
      container 'https://depot.galaxyproject.org/singularity/nextclade:2.13.1--h9ee0642_0'
    } else {
      container 'quay.io/biocontainers/nextclade:2.13.1--h9ee0642_0'
    }

    input:
    path consensus_fastas
    path dataset

    output:
    path("nextclade/"), optional:true, emit: outdir
    path("nextclade/nextclade.csv"), optional:true, emit: csv
    path("nextclade/nextclade.errors.csv"), optional:true, emit: csv_errors
    path("nextclade/nextclade.insertions.csv"), optional:true, emit: csv_insertions
    path("nextclade/nextclade.tsv"), optional:true, emit: tsv
    path("nextclade/nextclade.json"), optional:true, emit: json
    path("nextclade/nextclade.auspice.json"), optional:true, emit: json_auspice
    path("nextclade/nextclade.ndjson"), optional:true, emit: ndjson
    path("nextclade/nextclade.aligned.fasta"), optional:true, emit: fasta_aligned
    path("nextclade/nextclade.translation.fasta"), optional:true, emit: fasta_translation
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    """
    # TODO: appropriate segment sequences only?
    cat $consensus_fastas > combined_fastas.fa

    nextclade run \\
      $args \\
      --jobs $task.cpus \\
      --input-dataset $dataset \\
      --output-all ./nextclade/ \\
      combined_fastas.fa
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextclade: \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """
}



process NEXTCLADE_DATASETGET {
    label 'process_low'

    conda (params.enable_conda ? "bioconda::nextclade=2.13.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
      container 'https://depot.galaxyproject.org/singularity/nextclade:2.13.1--h9ee0642_0'
    } else {
      container 'quay.io/biocontainers/nextclade:2.13.1--h9ee0642_0'
    }

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
    nextclade dataset get \\
      $args \\
      --name $dataset \\
      $fasta \\
      $version \\
      --output-dir $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextclade: \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """
}
