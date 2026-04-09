process SAMTOOLS_SORT {
    tag "$meta.id"
    publishDir "${params.outdir}/bams", mode: 'copy'

    container 'community.wave.seqera.io/library/samtools:1.19.2--13401567ef54084f'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("*.sorted.bam"), emit: bam
    tuple val(meta), path("*.bai")       , emit: bai

    script:
    def prefix = "${meta.id}"
    """
    samtools view -bS $sam | samtools sort -@ $task.cpus -o ${prefix}.sorted.bam -
    samtools index ${prefix}.sorted.bam
    """
}
