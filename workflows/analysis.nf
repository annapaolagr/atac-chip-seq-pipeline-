// 1. Importazione dei moduli (Aggiunti i due Picard)
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { PICARD_ADDRG }           from '../modules/local/picard_addrg.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'

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

    // 3. Allineamento con Bowtie2 (Modulo "pulito" senza Read Groups)
    BOWTIE2 ( TRIMGALORE.out.reads, ch_index )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Picard: Correzione Read Groups (Prende l'output di Bowtie2)
    PICARD_ADDRG ( BOWTIE2.out.bam )

    // 5. Picard: Rimozione Duplicati (Prende l'output di AddRG)
    PICARD_MARKDUPLICATES ( PICARD_ADDRG.out.bam )

    // 6. Ordinamento e indicizzazione finale
    // Ora ordiniamo il file che è stato "pulito" dai duplicati
    SAMTOOLS_SORT ( PICARD_MARKDUPLICATES.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    emit:
    bam      = SAMTOOLS_SORT.out.bam
    bai      = SAMTOOLS_SORT.out.bai
    versions = ch_versions
}
