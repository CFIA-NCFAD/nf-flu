process PREPARE_NANOPORE_TEST {

  conda "conda-forge::perl"
  // use BLAST container here since it has Perl and is required by other
  // processes in the pipeline
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/blast:2.14.0--h7d5a4b4_1'
  } else {
    container 'quay.io/biocontainers/blast:2.14.0--h7d5a4b4_1'
  }

  input:

  output:
  path('*.csv'), emit: samplesheet

  script:
  """
  mkdir -p $PWD/nanopore_reads/{run1,run2}
  # IBV test data
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/SRR24826962.sampled.fastq.gz > $PWD/nanopore_reads/SRR24826962.fastq.gz
  # IAV test data
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/ERR6359501-10k.fastq.gz > $PWD/nanopore_reads/ERR6359501-10k.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/run1-s11-ERR6359501.fastq.gz > $PWD/nanopore_reads/run1/s11-ERR6359501.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/run1-s1-ERR6359501.fastq.gz > $PWD/nanopore_reads/run1/s1-ERR6359501.fastq.gz
  # uncompressed FASTQ should work too
  gunzip -f $PWD/nanopore_reads/run1/s1-ERR6359501.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/run2-s22-ERR6359501.fastq.gz > $PWD/nanopore_reads/run2/s22-ERR6359501.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/run2-s2-ERR6359501.fastq.gz > $PWD/nanopore_reads/run2/s2-ERR6359501.fastq.gz
  # neg ctrl
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/ntc-bc15.fastq.gz > $PWD/nanopore_reads/ntc-bc15.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/ntc-bc31.fastq.gz > $PWD/nanopore_reads/ntc-bc31.fastq.gz
  curl -SLk --silent https://github.com/CFIA-NCFAD/nf-test-datasets/raw/nf-flu/nanopore/fastq/ntc-bc47.fastq.gz > $PWD/nanopore_reads/ntc-bc47.fastq.gz

  # Prepare Sample sheet
  echo "sample,reads" | tee -a samplesheet.csv
  echo "ERR6359501-10k,$PWD/nanopore_reads/ERR6359501-10k.fastq.gz" | tee -a samplesheet.csv
  echo "ERR6359501,$PWD/nanopore_reads/run1" | tee -a samplesheet.csv
  echo "ERR6359501,$PWD/nanopore_reads/run2" | tee -a samplesheet.csv
  echo "SRR24826962,$PWD/nanopore_reads/SRR24826962.fastq.gz" | tee -a samplesheet.csv
  echo "ntc-bc15,$PWD/nanopore_reads/ntc-bc15.fastq.gz" | tee -a samplesheet.csv
  echo "ntc-bc31,$PWD/nanopore_reads/ntc-bc31.fastq.gz" | tee -a samplesheet.csv
  echo "ntc-bc47,$PWD/nanopore_reads/ntc-bc47.fastq.gz" | tee -a samplesheet.csv
  """
}
