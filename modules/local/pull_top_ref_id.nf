process PULL_TOP_REF_ID {
  tag "$meta.id"
  label 'process_low'

  conda 'conda-forge::python=3.10 conda-forge::biopython=1.80 conda-forge::openpyxl=3.1.0 conda-forge::pandas=1.5.3 conda-forge::rich=12.6.0 conda-forge::typer=0.7.0 conda-forge::xlsxwriter=3.0.8 conda-forge::polars=0.17.9 conda-forge::pyarrow=11.0.0'
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/mulled-v2-cfa20dfeb068db79c8620a11753add64c23d013a:019cd79f70be602ca625a1a0a4eabab462611a3a-0'
  } else {
    container 'quay.io/biocontainers/mulled-v2-cfa20dfeb068db79c8620a11753add64c23d013a:019cd79f70be602ca625a1a0a4eabab462611a3a-0'
  }

  input:
  tuple val(meta), path(blastn_results, stageAs: "blastn_results/*")
  path(genomeset)

  output:
  tuple val(meta), path("*.csv"), optional: true, emit: accession_id
  path "versions.yml", emit: versions

  script:
  """
  subtyping_report.py \\
    --flu-metadata $genomeset \\
    --get-top-ref \\
    --top 1 \\
    --pident-threshold $params.pident_threshold \\
    --sample-name ${meta.id} \\
    --input-blast-results-dir blastn_results/

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
     python: \$(python --version | sed 's/Python //g')
  END_VERSIONS
  """
}
