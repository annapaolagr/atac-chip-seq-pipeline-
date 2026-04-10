process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'

    container 'staphb/samtools:1.16.1'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.sorted.bam") , emit: bam
    tuple val(meta), path("*.bai")        , emit: bai
    path "versions.yml"                   , emit: versions

    script:
    def prefix = "${meta.id}.sorted"
    """
    samtools sort -@ $task.cpus -o ${prefix}.bam $bam
    samtools index -@ $task.cpus ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
