process TRIMGALORE {
    tag "${meta.id}"
    label 'process_high' // 

    // 
    container "${ workflow.containerEngine == 'singularity' ? 'https://depot.galaxyproject.org/singularity/trim-galore:0.6.7--0' : 'flexymeats/trim-galore:0.6.7' }"

    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads
    tuple val(meta), path("*_trimming_report.txt"), emit: log
    path "versions.yml" , emit: versions

    script:
    """
    trim_galore --paired --gzip ${reads[0]} ${reads[1]}

    cat <<EOF > versions.yml
    "${task.process}":
        trimgalore: \$(trim_galore --version | grep version | sed 's/.*version //')
    EOF
    """
}
