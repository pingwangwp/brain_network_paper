list=$(cat ./SubList/FileList11.txt)
RawPath=./UKBB/Imaging/rfMRI/rfMRI_20227
RefFile=/AAL_116_3mm.nii
LogPath=./UKBB/fMRI/FC_Data_Station/FC_FilePath_Log/
OutputPath_AAL=./UKBB/fMRI/FC_Matrix/AAL116/
UnusablePath=./UKBB/fMRI/FC_Data_Station/UnusableLog/

cd ./SubList/

for s in  $list 
do

PathUnzip=./UKBB/fMRI/FC_Data_Station/$s
ZipFile=$RawPath/$s
if [ ! -d $PathUnzip ];then
  mkdir $PathUnzip 
else
  echo "File exists"
fi
# unzip fMRI file to specific destination
unzip -d $PathUnzip $RawPath/$s


UsableFile=$PathUnzip/fMRI/rfMRI.ica/filtered_func_data_clean.nii.gz
if [ -f $UsableFile ];then


echo rfMRI of $s is usable
# apply warp file to MNI space
applywarp --ref=$RefFile --in=$PathUnzip/fMRI/rfMRI.ica/filtered_func_data_clean.nii.gz --out=$PathUnzip/MNI_filtered_func_data_clean --warp=$PathUnzip/fMRI/rfMRI.ica/reg/example_func2standard_warp
gunzip $PathUnzip/MNI_filtered_func_data_clean.nii.gz

# delete unziped file
rm -rf $PathUnzip/fMRI

# extract FC mat
#AAL 116
OutputFile=$OutputPath_AAL$s 
echo $PathUnzip > $LogPath$s
# 
Data_name=$PathUnzip/MNI_filtered_func_data_clean.nii
#
Path_template=./Template/AAL_116_3mm.nii

matlab -nosplash -nodesktop -r "FC_extract('$Data_name','$Path_template','$OutputFile')"


#delete MNI functional img
rm -rf $PathUnzip

else
echo rfMRI of $s is unusable
ls  $PathUnzip > $UnusablePath$s
rm -rf $PathUnzip
fi
 
done


