process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1'

    input:
    tuple val(meta), path(raw_bam)

    output:
    tuple val(meta), path("*.sorted.bam"), emit: bam
    path "versions.yml"                  , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools sort \\
        -@ $task.cpus \\
        -m 2G \\
        -o ${prefix}.sorted.bam \\
        $raw_bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
