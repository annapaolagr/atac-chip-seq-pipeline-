process BOWTIE2 {
    tag "$meta.id"
    
    container 'community.wave.seqera.io/library/bowtie2:2.5.2--069a6572f98650df'

    input:
    tuple val(meta), path(reads)
    path index_dir // La cartella che contiene gli indici .bt2

    output:
    tuple val(meta), path("*.sam"), emit: sam

    script:
    // Cerchiamo il nome base dell'indice (es. hg38) dentro la cartella
    def prefix = "${meta.id}_aln"
    """
    bowtie2 \\
        -x ${index_dir}/hg38 \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        --no-unal \\
        -p $task.cpus \\
        --very-sensitive \\
        --no-discordant \\
        -X 2000 \\
        -S ${prefix}.sam
    """
}
