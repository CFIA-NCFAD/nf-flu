process SNP_REPORT {
 tag "$sample"
 label 'process_low'
 conda 'conda-forge::python=3.9 conda-forge::biopython=1.78 conda-forge::openpyxl=3.0.7 conda-forge::pandas=1.2.4 conda-forge::rich=10.2.2 conda-forge::typer=0.3.2 conda-forge::xlsxwriter=1.4.3'
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/mulled-v2-693e24f156d01a5f55647120be99929b01b30949:609c862c3470382215fc1b2d9d8a4e9637b2e25f-0'
    } else {
        container 'quay.io/biocontainers/mulled-v2-693e24f156d01a5f55647120be99929b01b30949:609c862c3470382215fc1b2d9d8a4e9637b2e25f-0'
    }

  input:
  tuple val(sample), path(json)

  output:
  path('*.xlsx'), emit: report
  path "versions.yml", emit: versions

  script:
  """
  get_snp_report.py \\
   -x ${sample}-snp-report.xlsx \\
   -j $json
  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
    python: \$(python --version | sed 's/Python //g')
  END_VERSIONS
  """
}
