process TRIMGALORE {
    tag "${meta.id}"
    label 'process_high' 

    // Container stabile di Biocontainers
    container 'quay.io/biocontainers/trim-galore:0.6.10--hdfd78af_0'

    // Usiamo 'copy' per avere i file finali, ma puoi usare 'link' per test più veloci
    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz")              , emit: reads
    tuple val(meta), path("*_trimming_report.txt"), emit: log
    path "versions.yml"                           , emit: versions

    script:
    // SETTAGGIO TURBO: Forziamo 4 core per Cutadapt/Pigz. 
    // Nota: Trim Galore utilizzerà internamente fino a 7-8 CPU totali.
    def cores = 4
    """
    trim_galore \\
        --cores $cores \\
        --paired \\
        --gzip \\
        ${reads[0]} \\
        ${reads[1]}

    cat <<EOF > versions.yml
    "${task.process}":
        trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/ .*\$//')
        cutadapt: \$(cutadapt --version | head -n 1)
    EOF
    """
}
