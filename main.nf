nextflow.enable.dsl=2

// Questo file chiama il workflow
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

workflow {
    ch_input = Channel
        .fromFilePairs(params.input, checkIfExists: true)
        .map { name, files -> [ [id:name], files ] }


    ATAC_CHIP_PIPELINE ( ch_input )
}
