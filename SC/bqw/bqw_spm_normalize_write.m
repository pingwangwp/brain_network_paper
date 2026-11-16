function bqw_spm_normalize_write(datain,dartel_field,deformation_sn,opt)
if nargin <2
    fprintf('=======Write data to template based on deformation=====\n');
    fprintf('Format: bqw_spm_normalize_write(datain,dartel_field,deformation_sn,opt)\n');
    fprintf(' --datain:data paths need warpped, can be text file or cellstring\n');
    fprintf(' --dartel_field: dartel deformation field (y_*.nii)\n');
    fprintf(' --deformation_sn: _sn deformation field (*_sn.mat)\n');
    fprintf(' --opt:\n --opt.bondbox: bonding box\n --opt.voxsize:voxel size\n');
    fprintf(' --opt.interp:interpolation method, 0=neighboring,1=trilinear,2-4=B-spline\n');
    fprintf(' --opt.def_postfix:merged deformation postfix\n');
    fprintf(' --opt.outdir:output directory\n');
    fprintf(' --opt.prefix:prefix for output files\n');
    return
end

% read the data
if isstr(datain)
    fid=fopen(datain);
    tmp=textscan(fid,'%s');
    data=tmp{1};
elseif iscellstr(datain)
    data=datain;
end

datadir=fileparts(data{1});
if isempty(datadir)
    datadir=pwd;
end

if nargin<4
    opt.bondbox=[-90 -126 -72;90 90 108];
    opt.voxsize=[2 2 2];
    opt.interp =1;
    opt.outdir =datadir;
    opt.prefix ='MNI_';
    opt.def_postfix='affine_dartel.nii';
end

if ~isfield(opt,'bondbox');opt.bondbox=[-90 -126 -72;90 90 108];end
if ~isfield(opt,'voxsize');opt.voxsize=[2 2 2];end;
if ~isfield(opt,'interp') ;opt.interp =1;end;
if ~isfield(opt,'outdir') ;opt.outdir =datadir;end;
if ~isfield(opt,'prefix') ;opt.prefix ='MNI_';end;
if ~isfield(opt,'def_postfix'); opt.def_postfix='affine_dartel.nii';end;
if length(opt.voxsize)==1;opt.voxsize=repmat(opt.voxsize,1,3);end
if ~exist('dartel_field','var')
    dartel_field='';
end
if ~exist('deformation_sn','var')
    deformation_sn='';
end
% read the data
outdir=opt.outdir;
if isempty(outdir);outdir=pwd;end
%% write using only dartel
if ~isempty(dartel_field)&&isempty(deformation_sn)    
        dartel_write(data,dartel_field,opt)

end
%% write using only _sn deformation
if  isempty(dartel_field)&& ~isempty(deformation_sn)
    for n=1:length(data)
        affine_write(data,deformation_sn,opt);
    end
end
%% write using both affine and dartel
if  ~isempty(dartel_field)&& ~isempty(deformation_sn)
        def_dir=fileparts(deformation_sn);
        merged_field=[def_dir,filesep,opt.def_postfix];
        merged_field_inv=[def_dir,filesep,'iy_',opt.def_postfix];
        deform_merge(dartel_field,deformation_sn,merged_field,opt);
        field_in=[def_dir,filesep,'y_',opt.def_postfix];
deform_invert(field_in,data{1},merged_field_inv);
%     for n=1:length(data)
%         dartel_write(data{n},field_in,opt);
%     end
dartel_write(data,field_in,opt);
end
end

function dartel_write(data,dartel_field,opt)
        matlabbatch{1}.spm.spatial.normalise.write.subj.def = {dartel_field};
%         matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {data};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = data;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = opt.bondbox;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = opt.voxsize;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = opt.interp;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = opt.prefix;
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
end

function affine_write(data,deformation_sn,opt)
        matlabbatch{1}.spm.tools.oldnorm.write.subj.matname = deformation_sn;
        matlabbatch{1}.spm.tools.oldnorm.write.subj.resample = data;
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.preserve = 0;
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.bb = opt.bondbox
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.vox =opt.voxsize;
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.interp = 4;
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.tools.oldnorm.write.roptions.prefix =opt.prefix;
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
end

function deform_merge(dartel_field,deformation_sn,merged_field,opt)
       
[def_dir,def_name,ext]=fileparts(merged_field);
        if isempty(def_dir)
            def_dir=pwd;
        end
        matlabbatch{1}.spm.util.defs.comp{1}.sn2def.matname = {deformation_sn};
        matlabbatch{1}.spm.util.defs.comp{1}.sn2def.vox = [NaN NaN NaN];
        matlabbatch{1}.spm.util.defs.comp{1}.sn2def.bb = [NaN NaN NaN;NaN NaN NaN];
        matlabbatch{1}.spm.util.defs.comp{2}.def = {dartel_field};
        matlabbatch{1}.spm.util.defs.out{1}.savedef.ofname = [def_name,ext];
        matlabbatch{1}.spm.util.defs.out{1}.savedef.savedir.saveusr = {def_dir};
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
end

function deform_invert(field_in,reference,field_out)
        if nargin<3
            [tmpdir,fname,ext]=fileparts(field_in);
            if isempty(tmpdir);tmpdir=pwd;end
            field_out_dir=tmpdir;
            field_out_name=['iy_',fname(3:end),ext];
        else
            [tmpdir,fname,ext]=fileparts(field_out);
            field_out_dir=tmpdir;
            field_out_name=[fname,ext];
        end        
        matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.def = {field_in};
        matlabbatch{1}.spm.util.defs.comp{1}.inv.space = {reference};
        matlabbatch{1}.spm.util.defs.out{1}.savedef.ofname =field_out_name;
        matlabbatch{1}.spm.util.defs.out{1}.savedef.savedir.saveusr = {field_out_dir};
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch);
        movefile([field_out_dir,filesep,'y_',field_out_name],[field_out_dir,filesep,field_out_name]);
end
        
        
