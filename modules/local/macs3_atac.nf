process MACS3_ATAC {
    tag "$meta.id"
    label 'process_medium'
    
    container 'quay.io/biocontainers/macs3:3.0.0b1--py310h0db0f3a_1'

    publishDir "${params.outdir}/peaks", mode: 'copy'

    input:
    // Aggiungiamo il path per l'indice (bai) qui
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.narrowPeak")      , emit: peaks
    tuple val(meta), path("*.xls")             , emit: excel
    tuple val(meta), path("*_treat_pileup.bdg"), emit: bedgraph
    path "*.pdf"                               , emit: pdf_cutoff, optional: true

    script:
    def prefix = "${meta.id}"
    """
    macs3 callpeak \\
        -t $bam \\
        -f BAMPE \\
        -g hs \\
        -n $prefix \\
        -B \\
        --cutoff-analysis \\
        --keep-dup all \\
        --nomodel \\
        --shift -100 \\
        --extsize 200
    """
}
