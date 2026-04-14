process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    container 'staphb/bowtie2:2.4.4'

    input:
    tuple val(meta), path(reads)
    path index_dir 

    output:
    tuple val(meta), path("*.removed.bam"), emit: bam
    path "*.log"                          , emit: log
    path "versions.yml"                   , emit: versions

    script:
    def prefix = "${meta.id}_aln"
    // Alziamo i core totali a 12 (8 per bowtie, 4 per samtools)
    // Assicurati che nel nextflow.config il processo BOWTIE2 abbia cpus = 12
    def bt_cpus = 8
    def st_cpus = 4

    """
    INDEX_BASE=`find -L ${index_dir} -name "*.1.bt2" | sed "s/\\\\.1\\\\.bt2\\\$//"`

    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $bt_cpus \\
        --very-sensitive \\
        -X 2000 \\
        --no-mixed \\
        --no-discordant \\
        2> >(tee ${prefix}.bowtie2.log >&2) | \\
    samtools view -@ $st_cpus -uS - | \\
    samtools fixmate -@ $st_cpus -mu - - | \\
    samtools sort -@ $st_cpus -m 3G -u - | \\
    samtools markdup -@ $st_cpus -r - ${prefix}.removed.bam 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
