process FASTQC {
    tag "${meta.id}"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' ? 'https://depot.galaxyproject.org/singularity/fastqc:0.11.9--0' : 'biocontainers/fastqc:v0.11.9_cv8' }"
    
    publishDir "${params.outdir}/fastqc", mode: 'copy'


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path  "versions.yml"           , emit: versions

    script:
    // Usiamo $reads: Nextflow espanderà automaticamente tutti i file della coppia
    """
    fastqc $reads
    
    cat <<EOF > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//')
    EOF
    """
}
