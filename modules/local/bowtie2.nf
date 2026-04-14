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
    def bt_cpus = 6
    def st_cpus = 2

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
    samtools view -@ $st_cpus -bS - | \\
    samtools fixmate -@ $st_cpus -m - - | \\
    samtools sort -@ $st_cpus -m 2G - | \\
    samtools markdup -@ $st_cpus -r - ${prefix}.removed.bam 
    
    """
}
