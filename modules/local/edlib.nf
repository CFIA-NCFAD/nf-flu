process EDLIB_ALIGN {
  tag "$sample"
  label 'process_medium'

  conda 'conda-forge::python=3.10 conda-forge::biopython=1.80 conda-forge::pandas=1.5.3 conda-forge::rich=12.6.0 conda-forge::typer=0.7.0 bioconda::python-edlib=1.3.9'
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/mulled-v2-4627b14ef9fdc900fafc860cd08c19d7fbb92f43:3aae397a063ad1c6f510775118a2c5e6acbc027d-0'
  } else {
    container 'quay.io/biocontainers/mulled-v2-4627b14ef9fdc900fafc860cd08c19d7fbb92f43:3aae397a063ad1c6f510775118a2c5e6acbc027d-0'
  }

  input:
  tuple val(sample), path(consensus)
  path(fasta)

  output:
  tuple val(sample), path('*.txt'), emit: txt
  tuple val(sample), path('*.json'), emit: json
  path "versions.yml", emit: versions

  script:
  """
  edlib_align.py \\
    --sample $sample \\
    --consensus $consensus \\
    --reference $fasta
  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
    python: \$(python --version | sed 's/Python //g')
  END_VERSIONS
  """
}

process EDLIB_MULTIQC {
  label 'process_low'

  // using shiptv container since it has pandas, rich, typer installed
  conda 'bioconda::shiptv=0.4.0'
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/shiptv:0.4.0--pyh5e36f6f_0'
  } else {
    container 'quay.io/biocontainers/shiptv:0.4.0--pyh5e36f6f_0'
  }

  input:
  path(edlib_json)

  output:
  path('edlib_summary_mqc.txt'), emit: txt

  script:
  """
  edlib_multiqc.py \\
    edlib_summary_mqc.txt \\
    $edlib_json
  """
}
