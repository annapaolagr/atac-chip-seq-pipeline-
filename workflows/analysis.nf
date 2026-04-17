include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { FILTERING }              from '../modules/local/filtering.nf'
include { MACS3_ATAC_NARROW }      from '../modules/local/macs3_atac_narrow.nf'
include { MACS3_ATAC_BROAD }       from '../modules/local/macs3_atac_broad.nf'
include { MACS3_CHIP_NARROW }      from '../modules/local/macs3_chip_narrow.nf'
include { MACS3_CHIP_BROAD }       from '../modules/local/macs3_chip_broad.nf'
include { HOMER_ANNOTATEPEAKS }    from '../modules/local/homer_annotate.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    // [meta, [reads]]
    ch_index    // path_to_index_folder

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Trimming
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento
    BOWTIE2 ( TRIMGALORE.out.reads, ch_index )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Ordinamento
    SAMTOOLS_SORT ( BOWTIE2.out.bam )

    // 5. Rimozione Duplicati
    PICARD_MARKDUPLICATES ( SAMTOOLS_SORT.out.bam, [], [] )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions)

    // --- STEP 6: FILTRAGGIO ---
def blacklist_path = params.genomes[ params.genome ]?.blacklist ?: null

if (blacklist_path) {
    // Rimuoviamo 'checkIfExists: true' perché con gli URL remoti può dare problemi al primo avvio
    // Nextflow scaricherà l'URL e lo passerà al processo
    ch_blacklist = file(blacklist_path) 

    FILTERING ( PICARD_MARKDUPLICATES.out.bam, ch_blacklist )
    ch_final_bams = FILTERING.out.bam
    ch_versions = ch_versions.mix(FILTERING.out.versions)
} else {
    ch_final_bams = PICARD_MARKDUPLICATES.out.bam
}

    // --- STEP 7: PEAK CALLING ---
    ch_peaks = Channel.empty()

    if (params.protocol == 'atac') {
        MACS3_ATAC_NARROW ( ch_final_bams )
        MACS3_ATAC_BROAD  ( ch_final_bams )

        ch_peaks = MACS3_ATAC_NARROW.out.peaks.mix(MACS3_ATAC_BROAD.out.peaks)
        ch_versions = ch_versions.mix(
            MACS3_ATAC_NARROW.out.versions, 
            MACS3_ATAC_BROAD.out.versions
        )
    } 
    else if (params.protocol == 'chip') {
        
        // Isoliamo i controlli dai BAM già filtrati
        ch_control_bams = ch_final_bams
            .filter { meta, bam -> meta.antibody == 'none' || !meta.antibody || meta.antibody == '' }
            .map { meta, bam -> [ meta.id, bam ] }

        // Accoppiamo le IP ai rispettivi controlli
        ch_macs3_chip_input = ch_final_bams
            .filter { meta, bam -> meta.antibody && meta.antibody != 'none' && meta.antibody != '' }
            .map { meta, bam -> [ meta.control, meta, bam ] } 
            .join(ch_control_bams)
            .map { id_ctrl, meta, bam_ip, bam_ctrl -> [ meta, bam_ip, bam_ctrl ] }

        MACS3_CHIP_NARROW ( ch_macs3_chip_input )
        MACS3_CHIP_BROAD  ( ch_macs3_chip_input )

        ch_peaks = MACS3_CHIP_NARROW.out.peaks.mix(MACS3_CHIP_BROAD.out.peaks)
        ch_versions = ch_versions.mix(
            MACS3_CHIP_NARROW.out.versions, 
            MACS3_CHIP_BROAD.out.versions
        )
    }
def fasta = params.genomes[ params.genome ]?.fasta ?: null
    def gtf   = params.genomes[ params.genome ]?.gtf   ?: null

    if (fasta && gtf) {
        // Passiamo il canale dei picchi (che contiene sia narrow che broad)
        HOMER_ANNOTATEPEAKS ( 
            ch_peaks, 
            file(fasta), 
            file(gtf) 
        )
        ch_versions = ch_versions.mix(HOMER_ANNOTATEPEAKS.out.versions)
    } else {
        log.warn "HOMER: Fasta o GTF non trovati nel config. Annotazione saltata."
    }
    emit:
    bam      = ch_final_bams // Emettiamo i BAM filtrati, sono quelli pronti per IGV
    bai      = PICARD_MARKDUPLICATES.out.bai
    peaks    = ch_peaks
    versions = ch_versions
}
