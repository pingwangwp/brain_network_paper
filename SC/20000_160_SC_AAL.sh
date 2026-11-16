####Data pre

order_sub_begin=$1
num_sub=$2
Path=./UKBB_DTI_FotTianHe/Scipt/tianhe_scipt/

cat $Path/Resort_Zip_0701.txt | tail -n +$order_sub_begin | head -n $num_sub    > $Path/List/list_AAL_"$order_sub_begin"_"$num_sub".txt

list=$(cat $Path/List/list_AAL_"$order_sub_begin"_"$num_sub".txt)
for s in  $list  # s=1000066_20250_2_0
do 
currentdir=./UKBB_DTI_FotTianHe/Data_After_Resort_20000/                        ## Subjects id list
PathUnzip=./UKBB_DTI_FotTianHe/Data_After_Resort_20000/$s                       #一级diff文件夹
OutputPath_AAL=$PathUnzip/SC_AAL/

defild=$PathUnzip/dMRI/MNI_to_dti_FA_warp.nii

refe=$PathUnzip/dMRI/fdt/fdt_FA_clean.nii.gz
LogPath=$PathUnzip/
#######
cd ./scipt/
#########AAL_SC
########(defild,refe,inputs,OutPut)
t3=`date +%s` 
endtime=`date +'%Y-%m-%d %H:%M:%S'`
echo -e "------start tract AAL SC :$endtime ------\n" >> $LogPath/gradSort_$s.log                                                      
# endtime=`date +'%Y-%m-%d %H:%M:%S'`
#end_seconds=$(date --date="$endtime" +%s)
#timeused=$((end_seconds-start_seconds))
#echof -e "end time: $endtime"
inputs=./scipt/AAL_116_3mm.nii
OutPut_SC=$OutputPath_AAL/$s
if [ ! -d $OutPut_SC ];then
  mkdir -p $OutPut_SC

else
  echo "File exists"
fi
###########normalize mni to diff
if [ !  -f $OutPut_SC/hardi_fiber_summary.mat ];then
deformation_out=${inputs##*/}
applywarp --ref=$refe --in=$inputs --warp=$defild --interp=nn --out=$OutPut_SC/w${deformation_out}        >> $LogPath/gradSort_$s.log 2>&1
cd ./UKBB/dMRI/scipt/
##########extract SC

cmd2="matlab -nodesktop -nosplash -r fiber_split_TH_AAL('$s','$OutPut_SC/','$currentdir','$deformation_out')"      >> $LogPath/gradSort_$s.log 2>&1
$cmd2
mv $OutPut_SC/fiber_split/hardi_fiber_summary.mat $OutPut_SC
#zip -q -r -m $OutPut_SC/fiber_split.zip $OutPut_SC/fiber_split

t4=`date +%s` 
tu=$((t4-t3))
echo -e "------finish extract AAL SC in $tu seconds ------\n"   >> $LogPath/gradSort_$s.log 
else
echo -e "SC-AAL File exists------\n"  >> $LogPath/gradSort_$s.log 
fi
done