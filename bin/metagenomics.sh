#!/bin/bash
### type "qiime", then run this script ###
### biolinux qiime won't confuse usearch with usearch61 ###

map=/usr/local/bioinf/faesdata/metagenomics/map
FASTQ_DIR=/usr/local/bioinf/faesdata/metagenomics/fastq/*_R1_*
MAX_EE=1.0
MIN_SIZE=2
MIN_SAMPLES=2

cp -nR /usr/local/bioinf/faesdata/metagenomics/matplotlib $HOME/.config/
cd $HOME
rm -rf otus/; mkdir otus/; workdir=otus/; cd $workdir

usearch -fastq_mergepairs $FASTQ_DIR -relabel @ -fastqout merged.fastq
usearch -fastq_filter merged.fastq -fastq_maxee $MAX_EE \
	-fastaout seqs.fna
usearch -derep_fulllength seqs.fna -fastaout seqs.derep.fna -sizeout
usearch -cluster_otus seqs.derep.fna -sizein -minsize $MIN_SIZE \
	-otus rep_set.fa -relabel OTU_
usearch -usearch_global merged.fastq -db rep_set.fa \
        -id 0.97 -strand plus -biomout otu.biom

assign_taxonomy.py -i rep_set.fa -o .
align_seqs.py -i rep_set.fa -o .
filter_alignment.py -i *aligned* -o .
make_phylogeny.py -i *pfiltered* -o rep_set.tre
filter_otus_from_otu_table.py -i otu.biom -o otu.ms.biom \
                              -e *failures* --min_samples $MIN_SAMPLES
biom add-metadata -i otu.ms.biom -o otu_tax.biom \
        --observation-metadata-fp *assignments.txt \
        --sc-separated taxonomy --observation-header OTUID,taxonomy
biom convert -i otu_tax.biom -o otu_tax_classic.txt --to-tsv --header-key taxonomy
core_diversity_analyses.py -i otu_tax.biom -e 2000 -t rep_set.tre \
			   -m $map -o results/ -c Treatment
make_2d_plots.py -i ~/otus/results/bdiv_even2000/unweighted_unifrac_pc.txt -o ~/otus/results -m $map
make_2d_plots.py -i ~/otus/results/bdiv_even2000/weighted_unifrac_pc.txt -o ~/otus/results -m $map
