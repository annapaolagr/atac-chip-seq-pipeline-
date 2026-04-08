// Importiamo il modulo FastQC
include { FASTQC } from '../modules/local/fastqc'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_reads

    main:
    FASTQC(ch_reads)

    emit:
    html = FASTQC.out.html
    versions = FASTQC.out.versions
}
