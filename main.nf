nextflow.enable.dsl=2

// Importa il workflow principale
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

workflow {
    // 1. Canale per i file FASTQ (Input)
    // Trasforma [name, [f1, f2]] in [ [id:name], [f1, f2] ]
    ch_input = Channel
        .fromFilePairs(params.input, checkIfExists: true)
        .map { name, files -> [ [id:name], files ] }

    // 2. Logica Indice
    // Recupera il path dalla configurazione igenomes o dal parametro manuale
    def index_path = params.bowtie2_index ?: params.genomes[ params.genome ]?.bowtie2 ?: null

    if (!index_path) {
        error "Errore: Non trovo l'indice Bowtie2 per il genoma '${params.genome}'! Specifica --genome o --bowtie2_index"
    }

    // Creiamo il canale per l'indice. 
    // Usiamo checkIfExists: true per bloccare subito tutto se il path è sbagliato.
    ch_index = Channel.value(file(index_path, checkIfExists: true))

    // 3. Lanciamo il workflow
    ATAC_CHIP_PIPELINE ( ch_input, ch_index )
}
