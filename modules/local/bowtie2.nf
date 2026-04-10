process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    
    // Usiamo quay.io che è più veloce di DockerHub nel pull iniziale
    container 'quay.io/biocontainers/bowtie2:2.5.2--py310h7d7f7ad_0'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    // NOTA: Cambiamo l'output in BAM, è molto più leggero e veloce da gestire
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml"           , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    """
    # Individuiamo il basename dell'indice
    INDEX_BASE=\$(ls ${index_dir}/*.1.bt2 | head -n 1 | sed 's/\\.1\\.bt2//')

    # Allineamento e conversione immediata in BAM (senza scrivere il SAM sul disco)
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
