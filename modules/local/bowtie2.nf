process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    
    // Container che include sia Bowtie2 che Samtools
    container 'staphb/bowtie2:2.4.4'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    // Emette direttamente il BAM grezzo
    tuple val(meta), path("*.raw.bam"), emit: bam
    path "*.log"                      , emit: log
    path "versions.yml"               , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    """
    INDEX_BASE=\$(ls ${index_dir}/*.1.bt2 | head -n 1 | sed 's/\\.1\\.bt2//')

    # Allineamento e conversione diretta: il SAM non tocca mai il disco
    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $task.cpus \\
        --very-sensitive \\
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
