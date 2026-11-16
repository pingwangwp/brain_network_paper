function [img vol coordmm]=bqw_read_nii(V)
%=======================================================================
%% Format: [img vol coordmm]=bqw_read_nii(V)
%=======================================================================
% %% read nifti files
% V: volume to read, can be text or cell filepath, filelist, cellarry,or spm_vol structure volume.
% vol: spm volume information of nifti file
% img: data matrix
% coordmm: voxel coordination in mm
% Note: multiple files should be the same dimension and data type
% %----------Written by QIN WEN at 2018-04-01-----------
% =======================================================================

if ~nargin
    fprintf('==================read nifti files======================\nFormat: [img vol]=bqw_read_nii(V)\n');
    fprintf('Inputs:\n --V: volume to read: text file (containing image paths), string (directory or image path), cellarry (image paths),or spm_vol structure\n');
    fprintf('Output:\n --vol: spm volume structure\n --img: data matrix\n !!! Multiple images should have identical dimension and data type\n');
    fprintf('--coordmm: voxel coordination in mm:\n');
    fprintf('----------------Written by QinWen 2018-04-01------------\n');
    return;
end


% if V is characters
if ischar(V)
    if size(V,1)==1
        if exist(V,'dir')==7
            tmp=dir([V,filesep,'*.img']);
            if isempty(tmp)
                tmp=dir([V,filesep,'*.nii']);
            end
            if isempty(tmp)
                tmp=dir([V,filesep,'*.nii.gz']);
            end
            if ~isempty(tmp)
                Vt={};
                for i=1:length(tmp)
                    Vt{i,1}=[V,filesep,tmp(i).name];
                end
                V=Vt;
            else
                error('no nifti images in directory:%s\n',V);
            end
        elseif exist(V,'file')==2
            [tmpdir1,fname1,ext1]=fileparts(V);
            if strcmp(ext1,'.img')||strcmp(ext1,'.nii')||strcmp(ext1,'.gz')
                V=cellstr(V);
            else
                V=textread(V,'%s');
            end
        end
        
    else
        error('V must has only 1 element when input is string');
    end
end

if iscellstr(V)
    nf=length(V);
    vol=[];img=[];
    for n=1:nf
        [tmpdir,fname,ext]=fileparts(V{n});
        if isempty(tmpdir)
            tmpdir=pwd;
        end
        if strcmp(ext(1:3),'.gz')
            gunzip([tmpdir,filesep,fname,ext(1:3)]);
            vol=[vol;spm_vol([tmpdir,filesep,fname,',:'])];
            rm_list{n}=[tmpdir,filesep,fname];
        elseif strcmp(ext(1:4),'.img')||strcmp(ext(1:4),'.nii')
            vol=[vol;spm_vol([tmpdir,filesep,fname,ext,',:'])];            
        else
            fprintf('non-existence nifti image (nii,img,or nii,gz): %s\n',V{n});
            return
        end
    end
end
% if V is spm vol structure
if isstruct(V)
    vol=V;
end
% read data
img=spm_read_vols(vol);
img(isnan(img))=0;
img(isinf(img))=0;
if exist('rm_list') %#ok<EXIST>
    for r=1:length(rm_list)
        delete(rm_list{r});
    end
end
% output coordinations
if nargout>1
    [x,y,z]  = ndgrid(1:vol(1).dim(1),1:vol(1).dim(2),1:vol(1).dim(3));
    coordvox= [x(:)';y(:)';z(:)'];
    clear R C P
    coordvox(4,:) = 1;
    coordmm   = vol(1).mat(1:3,:)*coordvox;
    coordmm=coordmm';
end
