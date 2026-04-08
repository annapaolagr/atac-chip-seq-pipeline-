include { FASTQC     } from '../modules/local/fastqc.nf'
include { TRIMGALORE } from '../modules/local/trimgalore.nf' 

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input

    main:
    ch_versions = Channel.empty()

    // 1. Esegui FASTQC
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Esegui TrimGalore
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    emit:
    // Ora l'output della pipeline saranno le reads pulite
    reads    = TRIMGALORE.out.reads
    versions = ch_versions
}
