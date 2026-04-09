process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/bams", mode: 'copy'

    container 'community.wave.seqera.io/library/samtools:1.19.2--13401567ef54084f'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("*.sorted.bam")    , emit: bam
    tuple val(meta), path("*.sorted.bam.bai"), emit: bai // Modificato per chiarezza
    path "versions.yml"                      , emit: versions

    script:
    def prefix = "${meta.id}"
    """
    # Trasforma SAM in BAM, ordina e salva
    samtools view -bS $sam | samtools sort -@ $task.cpus -o ${prefix}.sorted.bam -
    
    # Crea l'indice del file BAM
    samtools index ${prefix}.sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
