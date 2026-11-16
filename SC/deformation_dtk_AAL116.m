%iy_pullback目前测试的配准最合适的方法，最近邻
function deformation_dtk_AAL116(defild,refe,inputs,OutPut)
inputsfiles={inputs};
%-----------------------------------------------------------------------
% Job saved on 06-May-2019 11:11:59 by cfg_util (rev $Rev: 6460 $)
% spm SPM - SPM12 (6470)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.defs.comp{1}.def = {defild};
matlabbatch{1}.spm.util.defs.comp{2}.id.space = {refe};
matlabbatch{1}.spm.util.defs.out{1}.pull.fnames =inputsfiles;
matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {OutPut};
matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 0;%Nearest neighbour
matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];

spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);
%Exclude 255 after normalize and reslice
%V1=spm_vol([OutPut,'/wBN_Atlas_274_combined.nii']);
%Img1=spm_read_vols(V1);
%IX=255;
%for i=1:max(Img1(:))
%    VoxNum(i,1)=length(find(Img1==i));
%end
%if VoxNum(IX,1)==0
%else
%    Img1(Img1==IX)=0;
%end
%for i=IX+1:max(Img1(:))
%    Img1(Img1==i)=Img1(Img1==i)-1;
%end
%V1.fname=[OutPut,'/wBN_Atlas_274_combined_Exclude255.nii'];
%spm_write_vol(V1,Img1);
exit
