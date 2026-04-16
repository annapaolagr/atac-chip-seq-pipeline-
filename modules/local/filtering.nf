process FILTERING {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:f70b31a2db15c023d641c32f433fb02cd04df5a6-0'

    publishDir "${params.outdir}/04_filtered", mode: 'copy'

    input:
    tuple val(meta), path(bam)
    path blacklist

    output:
    tuple val(meta), path("*.filtered.bam"), emit: bam
    path "versions.yml"                    , emit: versions

    script:
    def prefix = "${meta.id}"
    
    // Rileva il nome del mitocondrio (può essere chrM o M a seconda dell'indice)
    // Se protocol è ATAC, esegue il filtro samtools dopo bedtools
    def filter_command = (params.protocol == 'atac') ? 
        "| samtools view -h - | grep -v -E 'chrM|MT' | samtools view -b - > ${prefix}.filtered.bam" :
        "> ${prefix}.filtered.bam"

    """
    # 1. Rimuove regioni blacklist
    # 2. Se ATAC, rimuove anche reads mitocondriali (chrM o MT)
    bedtools intersect -v -abam $bam -b $blacklist $filter_command

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed 's/bedtools v//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
