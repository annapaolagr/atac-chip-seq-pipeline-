process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    
    // Questo container è ottimo perché ha entrambi i tool
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
    INDEX_BASE=\$(ls ${index_dir}/*.1.bt2 | head -n 1 | sed 's/\\.1\\.bt2//')

    # MODIFICA TURBO:
    # 1. Aggiungiamo i Read Groups qui (addio Picard Correct!)
    # 2. Usiamo -u in samtools view (BAM non compresso) per non affaticare la CPU
    bowtie2 \\
        -x \$INDEX_BASE \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p $task.cpus \\
        --very-sensitive \\
        -X 2000 \\
        --rg-id foo --rg "SM:${meta.id}" --rg "PL:illumina" --rg "LB:bar" \\
        2> ${prefix}.bowtie2.log \\
        | samtools view -@ $task.cpus -uS - > ${prefix}.raw.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/ .*\$//')
    END_VERSIONS
    """
}
