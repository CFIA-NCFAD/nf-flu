process IRMA {
  tag "$meta.id"
  label 'process_long'

  conda "bioconda::irma=1.0.2"
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/irma:1.0.2--pl5321hdfd78af_2'
  } else {
    container 'quay.io/biocontainers/irma:1.0.2--pl5321hdfd78af_2'
  }

  input:
  tuple val(meta), path(reads)
  val (irma_module)

  output:
  tuple val(meta), path("${meta.id}/"), emit: irma
  tuple val(meta), path("${meta.id}.irma.consensus.fasta"), optional: true, emit: consensus
  tuple val(meta), path("${meta.id}.irma.majority_consensus.fasta"), optional: true, emit: majority_consensus
  path "*.irma.log", emit: log
  path "versions.yml", emit: versions

  script:
  def irma_config = "DEL_TYPE=\"NNN\"\nALIGN_PROG=\"BLAT\""
  def irma_log    = "${meta.id}.irma.log"
  """
  touch irma_config.sh
  echo 'SINGLE_LOCAL_PROC=${task.cpus}' >> irma_config.sh
  echo 'DOUBLE_LOCAL_PROC=${(task.cpus / 2).toInteger()}' >> irma_config.sh
  # default tmp in current working directory instead of defaulting to /tmp 
  # which may be restricted in size on HPC clusters
  echo 'ALLOW_TMP=1' >> irma_config.sh
  echo 'TMP=\$PWD' >> irma_config.sh
  echo "MIN_LEN=${params.irma_min_len}" >> irma_config.sh
  if [ ${params.keep_ref_deletions} ]; then
    echo 'DEL_TYPE="NNN"' >> irma_config.sh
    echo 'ALIGN_PROG="BLAT"' >> irma_config.sh
  fi

  IRMA $irma_module $reads $meta.id

  cat_nonempty() {
    awk '
      # When a new header line is encountered
      /^>/ {
          # If there is an existing sequence (i.e., it is not empty), print the header and sequence
          if (seqlen > 0) {
              print header;
              print seq;
          }
          # Set the new header and reset the sequence and sequence length for the next entry
          header = \$0;
          seq = "";
          seqlen = 0;
          next;
      }

      # For sequence lines, concatenate the sequence and update the length
      {
          seq = seq \$0;
          seqlen += length(\$0);
      }

      # At the end of the file, print the last sequence if it is not empty
      END {
          if (seqlen > 0) {
              print header;
              print seq;
          }
      }
    ' \$@
  }

  if ls ${meta.id}/amended_consensus/*.fa > /dev/null 2>&1; then
    # use awk to concatenate only fasta sequences that actually have a sequence; ignore empty sequences
    cat_nonempty ${meta.id}/amended_consensus/*.fa > ${meta.id}.irma.consensus.fasta
  fi

  if ls ${meta.id}/tables/*-allAlleles.txt > /dev/null 2>&1; then
    irma-alleles2fasta -n "${meta.id}" -i "${meta.id}/tables" -o majority-consensus
    if ls majority-consensus/*.fasta > /dev/null 2>&1; then
      cat_nonempty majority-consensus/*.fasta > ${meta.id}.irma.majority_consensus.fasta
    fi
  fi

  ln -s .command.log $irma_log
  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
     IRMA: \$(IRMA | head -n1 | sed -E 's/^Iter.*IRMA\\), v(\\S+) .*/\\1/')
  END_VERSIONS
  """
}
