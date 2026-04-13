process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'

    container 'staphb/samtools:1.16.1'

  
    publishDir "${params.outdir}/final_bams", mode: 'copy'

    input:
    tuple val(meta), path(bam) 

    output:
    tuple val(meta), path("*.sorted.bam") , emit: bam
    tuple val(meta), path("*.bai")        , emit: bai
    path "versions.yml"                   , emit: versions

    script:
   
    def prefix = "${meta.id}.final"
  
    """
    samtools sort \\
        -@ $task.cpus \\
        -m 2G \\
        -o ${prefix}.sorted.bam \\
        $bam

    samtools index -@ $task.cpus ${prefix}.sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
