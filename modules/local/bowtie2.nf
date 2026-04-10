process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    
    // Cambiamo il container in uno che ha SIA Bowtie2 SIA Samtools (fondamentale per nf-core style)
    container 'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f022a66a41e76620ca557f146999fa9365:f0c6ceaf69cf66133496c6a66160938479e00661-0'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    tuple val(meta), path("*.raw.bam"), emit: bam
    tuple val(meta), path("*.log")    , emit: log
    path "versions.yml"               , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    """
    # 1. Trova il basename dell'indice
    INDEX_BASE=\$(ls ${index_dir}/*.1.bt2 | head -n 1 | sed 's/\\.1\\.bt2//')

    # 2. Allineamento e conversione in BAM. 
    # Grazie al 'pipefail' nel config, se bowtie2 fallisce, l'intera pipeline si ferma correttamente.
    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $task.cpus \\
        --very-sensitive \\
        --no-discordant \\
        -X 2000 \\
        2> ${prefix}.bowtie2.log \\
        | samtools view -@ $task.cpus -bS - > ${prefix}.raw.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
