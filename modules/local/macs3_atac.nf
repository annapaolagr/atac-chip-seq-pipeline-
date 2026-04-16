process MACS3_ATAC {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.0b1--py310h0db0f3a_1'

    publishDir "${params.outdir}/05_peaks", mode: 'copy'

    input:
    // Riceve il BAM rimosso e l'indice bai
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.narrowPeak")       , emit: peaks
    tuple val(meta), path("*.xls")              , emit: excel
    tuple val(meta), path("*_treat_pileup.bdg") , emit: bedgraph
    path "versions.yml"                         , emit: versions

    script:
    def prefix = "${meta.id}"
    // -f BAMPE è il gold standard per ATAC-seq se i dati sono Paired-End
    // --keep-dup all è ok perché abbiamo già rimosso i duplicati con Picard
    """
    macs3 callpeak \\
        -t $bam \\
        -f BAMPE \\
        -g hs \\
        -n $prefix \\
        -B \\
        -q 0.05 \\
        --keep-dup all

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //')
    END_VERSIONS
    """
}
