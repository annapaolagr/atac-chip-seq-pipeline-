process TRIMGALORE {
    tag "${meta.id}"
    label 'process_high'
   container 'https://depot.galaxyproject.org/singularity/trim-galore:0.6.6--0'

    publishDir "${params.outdir}/trimgalore", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads
    path "*.txt"                    , emit: report
    path "versions.yml"             , emit: versions

    script:
    // Definiamo se usare il comando --paired in base al numero di file ricevuti
    def paired = reads instanceof List && reads.size() > 1 ? "--paired" : ""
    """
    trim_galore $paired --fastqc $reads
    
    cat <<EOF > versions.yml
    "${task.process}":
        trimgalore: \$(trim_galore --version | grep version | sed 's/.*version //')
    EOF
    """
}
