process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    container 'quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:a1926674665489f6645398d363d596e9526e8310-0'

    input:
    tuple val(meta), path(reads)
    path  index // La cartella dell'indice

    output:
    tuple val(meta), path("*.raw.bam"), emit: bam
    tuple val(meta), path("*.log")    , emit: log
    path "versions.yml"               , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Aggiungiamo i Read Groups qui per non doverlo fare dopo
    def rg_args = "--rg-id ${prefix} --rg SM:${prefix} --rg PL:ILLUMINA --rg LB:lib1"
    
    """
    # Trova la base dell'indice in modo robusto
    INDEX_BASE=\$(find -L . -name "*.1.bt2" | sed 's/\\.1\\.bt2//' | head -n 1)

    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $task.cpus \\
        $rg_args \\
        --very-sensitive \\
        -X 2000 \\
        2> ${prefix}.bowtie2.log \\
        | samtools view -@ $task.cpus -b > ${prefix}.raw.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
