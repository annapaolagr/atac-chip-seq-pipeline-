nextflow.enable.dsl=2

// Questo file chiama il workflow
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

workflow {
    ch_input = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .view { "ID trovato: ${it[0]}" } 


    ATAC_CHIP_PIPELINE ( ch_input )
}
