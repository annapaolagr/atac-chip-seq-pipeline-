nextflow.enable.dsl=2

// Importa il workflow principale
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

workflow {
    // 1. Canale per i file FASTQ (Input)
    ch_input = Channel
        .fromFilePairs(params.input, checkIfExists: true)
        .map { name, files -> [ [id:name], files ] }

    // 2. Logica per recuperare l'indice da iGenomes
    // Cerchiamo nel dizionario 'genomes' (caricato da igenomes.config) 
    // il genoma passato tramite --genome (default hg38)
    def index_path = params.genomes[ params.genome ]?.bowtie2 ?: null

    if (!index_path) {
        error "Errore: Il genoma '${params.genome}' non è presente in igenomes.config!"
    }

    // Creiamo un canale 'valore' per l'indice (perché è uno solo per tutti i campioni)
    ch_index = Channel.value(file(index_path))

    // 3. Lanciamo il workflow passando sia le reads che l'indice
    ATAC_CHIP_PIPELINE ( ch_input, ch_index )
}
