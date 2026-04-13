process MACS3_ATAC {
    tag "$meta.id"
    label 'process_medium'
    
    container 'biocontainers/macs3:3.0.0b1-1_cv1'

    publishDir "${params.outdir}/peaks", mode: 'copy'

    input:
    tuple val(meta), path(bam)

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
        -f BAM \\
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
