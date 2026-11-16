#!/bin/bash

list=$(cat ./Dis1.txt)   #subject id list

for s in  $list 
do
 echo "$s"
inputs=./scripts/AAL116.nii
OutPut=./$s/AAL116   #output path
DataPath1=  # the data path

if [ -d ${DataPath1}/$s ];then
currentdir=$DataPath1
echo "$currentdir"


fi
rm -rf $OutPut
mkdir -p $OutPut
if [ ! -f ${OutPut}/dtk_fa.nii ];then
cp $currentdir/$s/dtk/dtk_fa.nii.gz  $OutPut
gunzip $OutPut/dtk_fa.nii.gz
fi
defild=$currentdir/$s/normalize/iy_affine_dartel.nii 
refe=$OutPut/dtk_fa.nii
cd /gpfs/lab/liangmeng/members/wangxiuzhi/YSX_BN/

cmd1="matlab -nodesktop -nosplash -r deformation_dtk_AAL116('$defild','$refe','$inputs','$OutPut')"
$cmd1
cmd2="matlab -nodesktop -nosplash -r fiber_split_TH_AAL116('$s','$OutPut','$currentdir')"
$cmd2
mv $OutPut/fiber_split/hardi_fiber_summary.mat $OutPut
zip -q -r -m $OutPut/fiber_split.zip $OutPut/fiber_split
echo "Now process is ${s}"

done