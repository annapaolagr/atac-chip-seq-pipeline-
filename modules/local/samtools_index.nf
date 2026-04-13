process SAMTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low' 
    container 'staphb/bowtie2:2.4.4' 

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai
    path "versions.yml"           , emit: versions

    script:
    """
    samtools index -@ $task.cpus $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
