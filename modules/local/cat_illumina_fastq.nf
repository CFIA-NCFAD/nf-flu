// modified nf-core/modules CAT_FASTQ
// for paired end reads append 1:N:0:. or 2:N:0:. forward and reverse reads 
// for compatability with IRMA assembly
process CAT_ILLUMINA_FASTQ {
  tag "$meta.id"
  label 'process_single'

  conda "conda-forge::perl"
  // use BLAST container here since it has Perl and is required by other
  // processes in the pipeline
  if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    container 'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1'
  } else {
    container 'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1'
  }

  input:
  tuple val(meta), path(reads, stageAs: "input*/*")

  output:
  tuple val(meta), path("*.merged.fastq.gz"), emit: reads

  when:
  task.ext.when == null || task.ext.when

  script:
  def args = task.ext.args ?: ''
  def prefix = task.ext.prefix ?: "${meta.id}"
  def readList = reads instanceof List ? reads.collect{ it.toString() } : [reads.toString()]
  def fqList = [] 
  def fqgzList = []
  readList.each { 
    if (it ==~ /^.*\.(fastq|fq)$/) {
      fqList << it
    } else if (it ==~ /^.*\.(fastq|fq)\.gz$/) {
      fqgzList << it
    }
  }
  if (meta.single_end) {
    if (fqList.size >= 1 || fqgzList.size >= 1) {
  """
  touch ${prefix}.merged.fastq.gz
  if [[ ${fqList.size} > 0 ]]; then
    cat ${readList.join(' ')} | gzip -ck >> ${prefix}.merged.fastq.gz
  fi
  if [[ ${fqgzList.size} > 0 ]]; then
    cat ${readList.join(' ')} >> ${prefix}.merged.fastq.gz
  fi
  """
    }
  } else {
    if (readList.size >= 2) {
      def read1 = []
      def read1gz = []
      def read2 = []
      def read2gz = []
      fqList.eachWithIndex { v, ix -> ( ix & 1 ? read2 : read1 ) << v }
      fqgzList.eachWithIndex { v, ix -> ( ix & 1 ? read2gz : read1gz ) << v }
      // append 1:N:0:. or 2:N:0:. to forward and reverse reads if "[12]:N:.*"
      // not present in the FASTQ header for compatability with IRMA assembly
"""
function modify_fastq_header() {
  local replacement="\$1"
  awk -v repl="\$replacement" '
    NR % 4 == 1 {
        # Only process the first line of each 4-line block
        if (\$0 ~ /^@/ && \$0 !~ /[12]:N:.*/) {
            sub(/\\s*\$/, " " repl ":N:0:."); # Append " <replacement>:N:0:."
        }
    }
    { print }
  '
}

touch ${prefix}_1.merged.fastq.gz

touch ${prefix}_2.merged.fastq.gz

if [[ ${read1.size} > 0 ]]; then
  cat ${read1.join(' ')} \\
  | modify_fastq_header 1 \\
  | gzip -ck \\
  >> ${prefix}_1.merged.fastq.gz
fi

if [[ ${read1gz.size} > 0 ]]; then
  zcat ${read1gz.join(' ')} \\
  | modify_fastq_header 1 \\
  | gzip -ck \\
  >> ${prefix}_1.merged.fastq.gz
fi

if [[ ${read2.size} > 0 ]]; then
  cat ${read2.join(' ')} \\
  | modify_fastq_header 2 \\
  | gzip -ck \\
  >> ${prefix}_2.merged.fastq.gz
fi

if [[ ${read2gz.size} > 0 ]]; then
  zcat ${read2gz.join(' ')} \\
  | modify_fastq_header 2 \\
  | gzip -ck \\
  >> ${prefix}_2.merged.fastq.gz
fi
"""
    }
  }
}
