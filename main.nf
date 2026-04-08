nextflow.enable.dsl=2

// Importiamo la funzione ATAC_CHIP_PIPELINE dal file analysis.nf
include { ATAC_CHIP_PIPELINE } from './workflows/analysis'

workflow {
    // Canale di input per i file FASTQ
    ch_input = Channel.fromFilePairs(params.reads, checkIfExists: true)

    // Lanciamo il workflow
    ATAC_CHIP_PIPELINE(ch_input)
}
