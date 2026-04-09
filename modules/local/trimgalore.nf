process TRIMGALORE {
    tag "${meta.id}"
    label 'process_high' 

    // Container aggiornato per gestire sia Docker che Singularity in modo fluido
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trim-galore:0.6.7--0' :
        'community.wave.seqera.io/library/trim-galore:0.6.10--1898717906969564' }"

    // Nota: Se hai già messo publishDir nel nextflow.config, qui puoi anche toglierlo
    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    // IMPORTANTE: TrimGalore genera file che finiscono in _val_1.fq.gz e _val_2.fq.gz
    tuple val(meta), path("*.fq.gz")              , emit: reads
    tuple val(meta), path("*_trimming_report.txt"), emit: log
    path "versions.yml"                           , emit: versions

    script:
    // Definiamo i parametri extra se necessario (opzionale)
    def args = task.ext.args ?: ''
    """
    trim_galore \\
        $args \\
        --paired \\
        --gzip \\
        ${reads[0]} \\
        ${reads[1]}

    cat <<EOF > versions.yml
    "${task.process}":
        trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/ .*\$//')
    EOF
    """
}
