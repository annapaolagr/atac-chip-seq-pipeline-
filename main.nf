nextflow.enable.dsl=2

// Importa il workflow principale
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

workflow {
    // 1. Canale per i file FASTQ (Input)
    // Trasforma [name, [f1, f2]] in [ [id:name, single_end:false], [f1, f2] ]
    // Aggiungiamo 'single_end:false' perché il modulo Bowtie2 di nf-core lo usa per decidere i flag
    ch_input = Channel
        .fromFilePairs(params.input, checkIfExists: true)
        .map { name, files -> 
            def meta = [id:name, single_end:false]
            return [ meta, files ] 
        }

    // Recupera il path dalla configurazione igenomes o dal parametro manuale
    def index_path = params.bowtie2_index ?: params.genomes[ params.genome ]?.bowtie2 ?: null

    if (!index_path) {
        error "Errore: Non trovo l'indice Bowtie2 per il genoma '${params.genome}'! Specifica --genome o --bowtie2_index"
    }

    // Lo passiamo come tuple [ [id:genome], path ] per essere 100% nf-core compliant
    ch_index = Channel.value([ [id:params.genome], file(index_path, checkIfExists: true) ])


    // 3. Lanciamo il workflow
    ATAC_CHIP_PIPELINE ( ch_input, ch_index )
}
