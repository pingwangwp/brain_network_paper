#!/bin/bash

DATASET=$1
CHR=$2
SIGSNP=$3

if [ $DATASET == 'UKBB' ];then
        BFILE='UKBB_genetics/ukb22828_c'$CHR'_b0_v3.UKBB_samplefilter.33716.osnp.HWE6_MAF001_INFO6'
elif [ $DATASET == 'CHIMGEN' ];then
        BFILE='CHIMGEN_genetics/chr'$CHR'.CHIMGEN_samplefilter.6800.osnp.HWE6_MAF001_INFO6'
fi

#add header for clump
if head -1 $SIGSNP|grep -qv '^SNP';then
        sed -i '1i SNP\trsid\tAF\tINFO\tSAMPLESIZE\tBETA\tSE\tP\ttrait' $SIGSNP
fi

#change chr 01-09 to 1-9
sed -i 's/^0//' $SIGSNP

#independent snps (LD independent, r2<0.1, within 3-Mb windows)
plink \
--bfile $BFILE \
--clump $SIGSNP --clump-r2 0.1 --clump-kb 3000 \
--out $SIGSNP

#loci (recorded the left and rightmost variant with r2 < 0.1 to an index SNP to define an associated clump;  added a 50-kb window on each side of the LD clump and combined overlapping LD clumps into a single locus.)
awk '{print $3}' $SIGSNP.clumped|grep -v '^SNP'|grep -v '^$' >$SIGSNP.clumped.snpid

~/software/plink \
--bfile $BFILE \
--tag-r2 0.1 --tag-kb 3000 \
--list-all \
--show-tags $SIGSNP.clumped.snpid \
--out $SIGSNP.clumped.snpid

awk '{OFS="\t";print $2,($5-1-50000<0)?0:$5-1-50000,$6+50000}' $SIGSNP.clumped.snpid.tags.list|grep -v '^CHR'|sort -k 1,1 -k 2,2n -k 3,3n >$SIGSNP.clumped.snpid.tags.list.50kb.bed

bedtools merge \
-i $SIGSNP.clumped.snpid.tags.list.50kb.bed|\
awk '{OFS="\t";print $0,NR}' >$SIGSNP.loci.bed

#leadsnp (the SNP with the lowest P-value in a loci)
~/miniconda3/envs/bioinfo/bin/bedtools intersect \
-a $SIGSNP.loci.bed \
-b <(grep -v 'CHR' $SIGSNP.clumped|grep -v '^$'|awk '{OFS="\t";print $1,$4-1,$4,$3,$5}') \
-wa -wb|\
sort -k 1,1 -k 2,2n -k 3,3n -k 9,9g|\
~/miniconda3/envs/bioinfo/bin/bedtools groupby -i - -g 1-3 -c 8,9 -o first >$SIGSNP.loci.leadsnp.bed

#leadsnp with further info
join -1 4 -2 1 <(sort -k 4,4 $SIGSNP.loci.leadsnp.bed) <(sort -k 1,1 $SIGSNP) |awk '{print $2,$3,$4,$1,$6,$7,$8,$9,$10,$11,$12,$13}' >$SIGSNP.loci.leadsnp.long.bed

