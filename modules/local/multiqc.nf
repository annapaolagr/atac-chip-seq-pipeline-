process MULTIQC {
    label 'process_medium'

    container "biocontainers/multiqc:1.23--pyhdfd78af_0"

    publishDir "${params.outdir}/00_MultiQC", mode: 'copy'

    input:
    path multiqc_config
    path ('fastqc/*')
    path ('trimgalore/*')
    path ('alignment/*')
    path ('picard/*')
    path ('samtools/*')
    path ('macs3/*')
    path ('frip/*')
    path versions

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "versions.yml"        , emit: versions

    script:
    def args = task.ext.args ?: ''
    def config = multiqc_config ? "--config $multiqc_config" : ''
    """
    multiqc \\
        -f \\
        $args \\
        $config \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //g')
    END_VERSIONS
    """
}
