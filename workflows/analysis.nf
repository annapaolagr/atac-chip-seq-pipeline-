// 1. Inclusione dei nuovi moduli aggiornati
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }          from '../modules/local/bowtie2.nf'
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

    // 3. Allineamento + Read Groups + Coordinate Sorting
    // Parametri: reads, index, save_unaligned (false), sort_bam (true)
    // Passiamo l'indice come richiesto dal modulo [meta_index, index] o solo path
    // Qui assumiamo che ch_index sia un semplice path come definito nel tuo workflow
    BOWTIE2_ALIGN ( 
        TRIMGALORE.out.reads, 
        ch_index, 
        false, 
        true 
    )
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions)

    // 4. Rimozione Duplicati PCR + Creazione Indice (.bai) con Picard
    // Passiamo liste vuote per FASTA e FAI se non li stiamo usando
    PICARD_MARKDUPLICATES ( 
        BOWTIE2_ALIGN.out.bam, 
        [[:], []], 
        [[:], []] 
    )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions)

    // 5. Peak Calling per ATAC-seq
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
