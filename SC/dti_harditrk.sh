#test list
#head -3 ./UKBB/rfMRI_FileList.txt > testlist.txt
#Path=./UKBB/dMRI/scipt/
#cat $Path/list0429.txt | tail -n +32 | head -n 1 > $Path/list_dti_32.txt
#list=$(cat "./UKBB/dMRI/scipt/list_dti_32.txt")

order_sub_begin=$1
num_sub=$2
Path=./UKBB_SC/scipts/

cat $Path/Check_Trk.txt | tail -n +$order_sub_begin | head -n $num_sub    > $Path/list_hardi_"$order_sub_begin"_"$num_sub".txt

list=$(cat $Path/list_hardi_"$order_sub_begin"_"$num_sub".txt)
for s in  $list  # s=1000066_20250_2_0
do

#s=1000037_20250_2_0

echo $s 
RawPath=./UKBB_DTI_FotTianHe/Zip_Resort/


DTI_Path=./UKBB/dMRI/dti_ori_0511/

UnusablePath=./UKBB/dMRI/UnusableLog/

currentdir=./UKBB_DTI_FotTianHe/Data_After_Resort/
path_trackvis_png=./UKBB_DTI_FotTianHe/Track_Png/


####每个被试的文件夹
PathUnzip=/$currentdir/$s


LogPath=$PathUnzip/
if [ ! -d  $PathUnzip ];then
mkdir -p  $PathUnzip
fi

starttime=`date +'%Y-%m-%d %H:%M:%S'`   
echo -e "------start diff pipline :$starttime------\n" > $LogPath/gradSort_$s.log # endtime=`date +'%Y-%m-%d %H:%M:%S'` 
start_seconds=$(date --date="$starttime" +%s)  
t1=`date +%s` 
##### $currentdir/$s/dMRI/dtk/hardi.trk




##### unzip fMRI file to specific destination

mkdir -p  $PathUnzip/dMRI/eddy
tar -xzvf $RawPath/$s.tar.gz -C $PathUnzip/dMRI/eddy




#########detele ZiPFILE 
#rm -rf $DTI_Path/$s/
#######resort VOLUME


###########调用diff程序


./pipe_diff_rev20220513 --datain=$PathUnzip//dMRI/eddy/data_brain.nii.gz --outdir=$PathUnzip/dMRI  --pipe=track --fibmodel="hardi" --gradT=-iz    >> $LogPath/gradSort_$s.log 2>&1
## 保存图像以便质控
track_vis $PathUnzip/dMRI/dtk/hardi.trk   --screen_capture $path_trackvis_png/$s.png 1 1 1 -skip 8  -bc 255 255 255
#########删除fdt文件
if [ -f $PathUnzip//dMRI//fdt/fdt_FA.nii.gz ];then
for m in FA  L1 L2 L3  MD MO S0 V1 V2 V3;
do
rm -f $PathUnzip//dMRI//fdt/fdt_$m.nii.gz
done
fi
## MNI_to_dti_FA_warp.ni复制到前一路径下 以便删去eddy  
cp $PathUnzip//dMRI/eddy/MNI_to_dti_FA_warp.nii.gz  $PathUnzip//dMRI
if [ -f $PathUnzip//dMRI/MNI_to_dti_FA_warp.nii.gz ];then
rm -rf $PathUnzip//dMRI/eddy
fi
if [ -f $PathUnzip/dMRI/dtk/hardi.trk ];then            
for n in b0  dwi max odf ;
do
rm -f $PathUnzip//dMRI/dtk/hardi_$n.nii.gz
done
rm -f $PathUnzip//dMRI/dtk/odf_tracker.log
rm -f $PathUnzip//dMRI/dtk/dtk_dgt
fi
done








