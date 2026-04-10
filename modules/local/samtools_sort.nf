process SAMTOOLS_SORT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/bams", mode: 'copy'

    container 'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0'

    input:
    // Cambiato da 'path(sam)' a 'path(bam)' perché Bowtie2 ora sputa BAM
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.sorted.bam")    , emit: bam
    tuple val(meta), path("*.sorted.bam.bai"), emit: bai 
    path "versions.yml"                      , emit: versions

    script:
    def prefix = "${meta.id}"
    """
    # Ordiniamo direttamente il file BAM grezzo
    # Usiamo -@ $task.cpus per parallelizzare il sorting (fondamentale per la velocità!)
    samtools sort -@ $task.cpus -o ${prefix}.sorted.bam $bam
    
    # Crea l'indice del file BAM ordinato
    samtools index -@ $task.cpus ${prefix}.sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
