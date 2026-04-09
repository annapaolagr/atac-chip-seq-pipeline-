process BOWTIE2 {
    tag "$meta.id"
    label 'process_high' // Per usare le risorse (CPU/RAM) del config

    container 'community.wave.seqera.io/library/bowtie2:2.5.2--069a6572f98650df'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    tuple val(meta), path("*.sam"), emit: sam
    tuple val(meta), path("*.log"), emit: log
    // Aggiungiamo anche le versioni (buona pratica nf-core)
    path  "versions.yml"          , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    """
    # Individua il basename dell'indice (funziona con hg38, mm10, o genome)
    INDEX_BASE=\$(ls ${index_dir}/*.1.bt2 | sed 's/\\.1\\.bt2//')

    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        --no-unal \\
        -p $task.cpus \\
        --very-sensitive \\
        --no-discordant \\
        -X 2000 \\
        -S ${prefix}.sam \\
        2> ${prefix}.bowtie2.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
    END_VERSIONS
    """
}
