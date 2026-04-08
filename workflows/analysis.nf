nextflow.enable.dsl=2

// Importiamo il workflow dal file analysis.nf
include { ATAC_CHIP_PIPELINE } from './workflows/analysis'

workflow {
    // Creiamo il canale di input. 
    // .fromFilePairs cerca coppie di file e 'name' diventa l'ID del campione.
    ch_input = Channel
        .fromFilePairs(params.input, checkIfExists: true)
        .map { name, files -> [ [id:name], files ] }

    // Lanciamo la pipeline passandogli il canale
    ATAC_CHIP_PIPELINE ( ch_input )
}
