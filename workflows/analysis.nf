// 1. Inclusione dei nuovi moduli aggiornati
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { MACS3_ATAC }             from '../modules/local/macs3_atac.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    // [meta, [reads_1, reads_2]]
    ch_index    // path_to_index_folder

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Trimming
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento (Produce il RAW BAM con Read Groups)
    BOWTIE2 ( 
        TRIMGALORE.out.reads, 
        ch_index 
    )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Ordinamento Coordinate 
    SAMTOOLS_SORT ( BOWTIE2.out.bam )

    // 5. Rimozione Duplicati (Riceve il file SORTED)
    PICARD_MARKDUPLICATES ( 
        SAMTOOLS_SORT.out.bam, 
        [[:], []], 
        [[:], []] 
    )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions)

    // 6. Peak Calling per ATAC-seq
    // Prepariamo l'input per MACS3 unendo il BAM deduplicato e il suo BAI generato da Picard
    ch_macs3_input = PICARD_MARKDUPLICATES.out.bam
        .join(PICARD_MARKDUPLICATES.out.bai)
    
    MACS3_ATAC ( ch_macs3_input )

    emit:
    bam      = PICARD_MARKDUPLICATES.out.bam
    bai      = PICARD_MARKDUPLICATES.out.bai
    peaks    = MACS3_ATAC.out.peaks
    versions = ch_versions
}
