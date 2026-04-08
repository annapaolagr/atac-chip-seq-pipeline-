process TRIMGALORE {
    tag "$meta.id"
    label 'process_medium'
    
    // Usiamo Singularity come abbiamo deciso prima
    container 'biocontainers/trim-galore:0.6.6--0'

    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads
    path "*.txt"                    , emit: report

    script:
    """
    trim_galore --paired --fastqc $reads
    """
}
