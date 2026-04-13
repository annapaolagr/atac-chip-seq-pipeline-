process PICARD_ADDRG {
    tag "$meta.id"
    container 'broadinstitute/picard:2.27.4'

    input:
    tuple val(meta), path(bam) 

    output:
    tuple val(meta), path("*_corrected.bam"), emit: bam

    script:
    """
    java -Xmx8g -jar /usr/picard/picard.jar AddOrReplaceReadGroups \\
        I=$bam \\
        O=${meta.id}_corrected.bam \\
        RGID=foo RGLB=bar RGPL=illumina RGPU=unit1 RGSM=${meta.id} \\
        CREATE_INDEX=True \\
        VALIDATION_STRINGENCY=SILENT
    """
}
