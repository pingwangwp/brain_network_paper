#!/bin/bash

DATASET=$1
CHR=$2
PHENO=$3
COVAR=$4
OUT=$5

if [ $DATASET == 'UKBB' ];then
        BGEN='UKBB_genetics/ukb22828_c'$CHR'_b0_v3.UKBB_samplefilter.33716.osnp.HWE6_MAF001_INFO6.bgen'
elif [ $DATASET == 'CHIMGEN' ];then
        BGEN='CHIMGEN_genetics/chr'$CHR'.CHIMGEN_samplefilter.6800.osnp.HWE6_MAF001_INFO6.bgen'
fi

echo 'bgen file: '$BGEN
echo "chr: "$CHR

~/software/bgenie_v1.3_static2 \
--bgen $BGEN \
--pheno $PHENO \
--covar $COVAR \
--pvals \
--out $OUT$CHR
