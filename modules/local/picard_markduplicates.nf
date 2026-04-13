process PICARD_MARKDUPLICATES {
    tag "$meta.id"
    container 'broadinstitute/picard:2.27.4'
    publishDir "${params.outdir}/deduplicated", mode: 'copy'

    input:
    tuple val(meta), path(bam) 

    output:
    tuple val(meta), path("*_removed.bam"), emit: bam
    path "*.txt"                          , emit: metrics

    script:
    """
    java -Xmx8g -jar /usr/picard/picard.jar MarkDuplicates \\
        I=$bam \\
        O=${meta.id}_removed.bam \\
        M=${meta.id}_marked_dup_metrics.txt \\
        REMOVE_DUPLICATES=true \\
        VALIDATION_STRINGENCY=SILENT
    """
}
