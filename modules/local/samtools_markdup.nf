process SAMTOOLS_MARKDUP {
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/samtools:1.16.1'

    publishDir "${params.outdir}/alignment/deduplicated", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.dedup.bam"), emit: bam
    path "*.stats"                     , emit: stats

    script:
    def prefix = "${meta.id}"
    """
    # 1. Fixmate: riempie i tag necessari per identificare i duplicati
    samtools fixmate -m $bam ${prefix}.fixmate.bam

    # 2. Sort: ordina il file fixmate (necessario per markdup)
    samtools sort -@ $task.cpus -o ${prefix}.resort.bam ${prefix}.fixmate.bam

    # 3. Markdup: rimuove i duplicati (-r)
    samtools markdup -r -@ $task.cpus ${prefix}.resort.bam ${prefix}.dedup.bam

    # 4. Statistiche e Indice finale
    samtools flagstat ${prefix}.dedup.bam > ${prefix}.dedup.bam.stats
    samtools index ${prefix}.dedup.bam
    
    # Pulizia file temporanei per non occupare spazio
    rm ${prefix}.fixmate.bam ${prefix}.resort.bam
    """
}
