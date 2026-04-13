process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    
    container 'staphb/bowtie2:2.4.4'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    tuple val(meta), path("*.raw.bam"), emit: bam
    path "*.log"                      , emit: log
    path "versions.yml"               , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    """
    # 1. Identifica la base dell'indice (Logica robusta stile nf-core)
    INDEX_BASE=`find -L ${index_dir} -name "*.1.bt2" | sed "s/\\.1\\.bt2\$//"`

    # 2. Allineamento 
    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $task.cpus \\
        --very-sensitive \\
        -X 2000 \\
        --no-mixed \\
        --no-discordant \\
        2> >(tee ${prefix}.bowtie2.log >&2) \\
        | samtools view -@ $task.cpus -u -F 4 -b - > ${prefix}.raw.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
