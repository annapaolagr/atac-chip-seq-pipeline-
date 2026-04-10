process TRIMGALORE {
    tag "${meta.id}"
    label 'process_high' 

    container 'quay.io/biocontainers/trim-galore:0.6.10--hdfd78af_0'

    // NOTA: Se vuoi velocità massima, sposta publishDir nel nextflow.config 
    // o usa mode: 'link' per non perdere tempo a copiare i file
    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz")              , emit: reads
    tuple val(meta), path("*_trimming_report.txt"), emit: log
    path "versions.yml"                           , emit: versions

    script:
    // 1. LOGICA NF-CORE PER I CORES
    // Trim Galore lancia Cutadapt e pigz. 
    // Se assegni 8 CPU nel config, questa formula dice a Trim Galore di usarne 
    // 4 per Cutadapt/pigz, che è il setup più veloce possibile.
    def cores = 1
    if (task.cpus > 1) {
        cores = (task.cpus / 4) as int
        if (cores < 1) cores = 1
    }
    
    def args = task.ext.args ?: ''
    """
    trim_galore \\
        $args \\
        --cores $cores \\
        --paired \\
        --gzip \\
        --no_report_if_cutadapt_not_found \\
        ${reads[0]} \\
        ${reads[1]}

    cat <<EOF > versions.yml
    "${task.process}":
        trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/ .*\$//')
        cutadapt: \$(cutadapt --version | head -n 1)
    EOF
    """
}
