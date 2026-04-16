nextflow.enable.dsl=2

// Importa il workflow principale
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'

// Funzione di supporto per pulire i dati del CSV
def create_fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample
    meta.antibody   = row.antibody ?: 'none'
    meta.control    = row.control ?: 'none'
    // Se fastq_2 è vuoto nel CSV, è Single-End
    meta.single_end = row.fastq_2 ? false : true

    def fastq_1 = file(row.fastq_1, checkIfExists: true)
    
    // Creiamo la lista di file (una o due reads)
    def fastqs = []
    if (meta.single_end) {
        fastqs = [ fastq_1 ]
    } else {
        def fastq_2 = file(row.fastq_2, checkIfExists: true)
        fastqs = [ fastq_1, fastq_2 ]
    }

    return [ meta, fastqs ]
}

workflow {
    // 1. Lettura del Samplesheet (CSV)
    // Sostituiamo fromFilePairs con splitCsv
    ch_input = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header:true, sep:',')
        .map { row -> create_fastq_channel(row) }

    // 2. Gestione Indice Bowtie2
    def index_path = params.bowtie2_index ?: params.genomes[ params.genome ]?.bowtie2 ?: null

    if (!index_path) {
        error "Errore: Non trovo l'indice Bowtie2 per il genoma '${params.genome}'!"
    }

    // Usiamo collect() per assicurarci che l'indice sia inviato a TUTTI i campioni
    ch_index = Channel.fromPath(index_path, checkIfExists: true).collect()

    // 3. Lanciamo il workflow
    // Ora ch_input contiene [meta, [file]] e meta ha anche le info su antibody e control
    ATAC_CHIP_PIPELINE ( ch_input, ch_index )
}
