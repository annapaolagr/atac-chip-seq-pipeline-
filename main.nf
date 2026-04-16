nextflow.enable.dsl=2

// Importa il workflow principale
include { ATAC_CHIP_PIPELINE } from './workflows/analysis.nf'


def create_fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample.trim()
    meta.antibody   = row.antibody ? row.antibody.trim() : 'none'
    meta.control    = row.control ? row.control.trim() : 'none'
    
    // Verifica se fastq_2 esiste ed è valorizzato nel CSV
    meta.single_end = row.fastq_2 ? false : true

    // Definizione file path
    def fastq_1 = file(row.fastq_1, checkIfExists: true)
    def fastqs = [ fastq_1 ]
    
    if (!meta.single_end) {
        def fastq_2 = file(row.fastq_2, checkIfExists: true)
        fastqs << fastq_2
    }

    return [ meta, fastqs ]
}

workflow {
    // 1. Lettura del Samplesheet (CSV)
    ch_input = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header:true, sep:',')
        .map { row -> create_fastq_channel(row) }

    // 2. Gestione Indice Bowtie2
    def index_path = params.bowtie2_index ?: params.genomes[ params.genome ]?.bowtie2 ?: null

    if (!index_path) {
        error "Errore: Non trovo l'indice Bowtie2 per il genoma '${params.genome}'! Specifica --genome o --bowtie2_index"
    }

    // Usiamo collect() per assicurarci che l'indice sia disponibile per ogni processo parallelo
    ch_index = Channel.fromPath(index_path, checkIfExists: true).collect()

    // 3. Esecuzione della Pipeline
    ATAC_CHIP_PIPELINE ( ch_input, ch_index )
}
