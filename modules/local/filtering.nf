process FILTERING {
    tag "$meta.id"
    label 'process_medium'
    // Questo container contiene sia bedtools che samtools
    container 'quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:f70b31a2db15c023d641c32f433fb02cd04df5a6-0'

    publishDir "${params.outdir}/04_filtered", mode: 'copy'

    input:
    tuple val(meta), path(bam)
    path  blacklist

    output:
    tuple val(meta), path("*.filtered.bam"), emit: bam
    path "versions.yml"                    , emit: versions

    script:
    def prefix = "${meta.id}"
    
    // Prepariamo il comando di filtraggio mitocondriale per ATAC
    // Usiamo samtools view per filtrare via chrM e MT in modo pulito
    def atac_filter = (params.protocol == 'atac') ? 
        "| samtools view -h - | awk '\$3 != \"chrM\" && \$3 != \"MT\" && \$3 != \"M\"' | samtools view -bS -" : 
        ""

    """
    # 1. Gestione Blacklist (decomprime se necessario)
    if [[ "$blacklist" == *.gz ]]; then
        gunzip -c "$blacklist" > actual_blacklist.bed
    else
        ln -s "$blacklist" actual_blacklist.bed
    fi

    # 2. Esecuzione Filtraggio
    # bedtools rimuove la blacklist, poi l'output va in pipe (se ATAC) o direttamente a file
    bedtools intersect -v -abam $bam -b actual_blacklist.bed $atac_filter > ${prefix}.filtered.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed 's/bedtools v//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
