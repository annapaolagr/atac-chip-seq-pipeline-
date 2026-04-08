process FASTQC {
    tag "$sample_id"
    label 'process_low'

    // Container specifico per la versione 0.12.1
    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.html"), emit: html
    tuple val(sample_id), path("*.zip") , emit: zip
    path "versions.yml"                 , emit: versions

    script:
    """
    fastqc --threads $task.cpus --quiet ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """
}
