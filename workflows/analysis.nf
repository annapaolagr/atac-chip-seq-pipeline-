// 1. Importazione dei moduli
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { PICARD_ADDRG }           from '../modules/local/picard_addrg.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'
include { MACS3_ATAC }             from '../modules/local/macs3_atac.nf' // <--- Aggiunto

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    // Canale con le reads (meta, [r1, r2])
    ch_index    // Canale con l'indice del genoma

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Pulizia reads (Trimming)
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento con Bowtie2
    BOWTIE2 ( TRIMGALORE.out.reads, ch_index )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Picard: Correzione Read Groups (Aggiunge ID campione indispensabile per Picard)
    PICARD_ADDRG ( BOWTIE2.out.bam )

    // 5. Picard: Rimozione Duplicati (Il tuo "removed.bam")
    PICARD_MARKDUPLICATES ( PICARD_ADDRG.out.bam )

    // 6. Ordinamento e indicizzazione finale (Il tuo "sorted.bam")
    SAMTOOLS_SORT ( PICARD_MARKDUPLICATES.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    // 7. Peak Calling specifico per ATAC-seq
    // Prende il file filtrato e ordinato da Samtools
    MACS3_ATAC ( SAMTOOLS_SORT.out.bam )

    emit:
    bam      = SAMTOOLS_SORT.out.bam
    bai      = SAMTOOLS_SORT.out.bai
    peaks    = MACS3_ATAC.out.peaks // <--- Output finale dei picchi
    versions = ch_versions
}
