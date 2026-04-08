// Importiamo i moduli locali
include { FASTQC     } from '../modules/local/fastqc'
include { TRIMGALORE } from '../modules/local/trimgalore'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input // Riceve il canale: [ [id:campione], [file1, file2] ]

    main:
    ch_versions = Channel.empty()

    // 1. Eseguiamo FastQC sui dati grezzi
    // Passiamo tutto l'oggetto ch_input (meta + file)
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Eseguiamo TrimGalore per pulire le reads
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    emit:
    trimmed_reads = TRIMGALORE.out.reads
    versions      = ch_versions
}
