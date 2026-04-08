// Questo file importa i moduli e definisce la logica
include { FASTQC     } from '../modules/local/fastqc.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input

    main:
    ch_versions = Channel.empty()

    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

   

    emit:
    versions      = ch_versions
}
