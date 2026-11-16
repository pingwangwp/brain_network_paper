function bqw_spm_normalize_estimate(source,target,opt)
if nargin < 2
fprintf('========= Coregistration Estimation ==========\n')
fprintf('Format: bqw_spm_normalize_estimate(source,target,opt)\n');
fprintf('--source: path of source image need be coregistered\n');
fprintf('--target: path of target image (template)\n');
fprintf('--opt:\n--opt.method:''affreg'',''flirt'',''bbr'',''oldnorm'',''dartel'',''fnirt''\n');  
fprintf('--opt.def_out: deformation output path\n--opt.source_out:source images output path\n');
fprintf('++++++++ Written by QinWen at 20181228 +++++++\n');
return
end
opt.script_dir=fileparts(which('bqw_spm_normalize_estimate'));
[source_dir]=fileparts(source);
if isempty(source_dir)
source_dir=pwd;
end
opt_fields={'method','def_out','cleanup','bbr','affreg','flirt','dartel','fnirt'};
if nargin<3;
for o=1:length(opt_fields)
eval(['opt.',opt_fields{o},'='''';']);
end
end
for o=1:length(opt_fields)
if ~isfield(opt,eval(['''',opt_fields{o},'''']));eval(['opt.',opt_fields{o},'='''';']);end
end
if isempty(opt.method);opt.method='oldnorm';end
if isempty(opt.def_out)
switch opt.method
case 'affreg'
opt.def_out=[source_dir,filesep,'affreg_sn.mat'];
case 'flirt'
opt.def_out=[source_dir,filesep,'flirt_sn.mat'];
case 'bbr'
opt.def_out=[source_dir,filesep,'bbr_sn.mat'];
case 'oldnorm'
opt.def_out=[source_dir,filesep,'oldnorm_sn.mat'];
case 'dartel'
opt.def_out=[source_dir,filesep,'y_dartel.nii'];
case 'fnirt'
opt.def_out=[source_dir,filesep,'fnirt_warp.nii'];
case ''
opt.def_out=[source_dir,filesep,'oldnorm_sn.mat'];
end
end

[def_dir,def_name,def_ext]=fileparts(opt.def_out);
if isempty(def_dir)
def_dir=source_dir;
opt.def_out=[def_dir,filesep,def_name,def_ext];
end


switch opt.method
case 'affreg'
cfg.matname=opt.def_out;
bqw_affreg_estimate({target},{source},cfg);

case 'flirt'
flirt_mat=[def_dir,'flirt.mat'];
flirt_cmd=['flirt -in  ',source,' -ref ',target,' -omat ',flirt_mat,' -searchrx -180 180 -searchry -180 180 -searchrz -180 180' ];
system(flirt_cmd);
mat_convert(source,target,flirt_mat,opt.def_out);

case 'bbr'
if ~isfield(opt.bbr,'wmseg');opt.bbr.wmseg='';end
if ~isfield(opt.bbr,'t1brain');opt.bbr.t1brain='';end
[targ_dir,targ_fname,targ_ext]=fileparts(target);
if ~exist(opt.def_out,'file')
bbr_out=[def_dir,filesep,'bbr'];
if ~exist([bbr_out,'.mat'],'file')
if isempty(targ_dir);targ_dir=pwd;end
if ~exist(opt.bbr.wmseg,'file')|| ~exist(opt.bbr.t1brain,'file')
mT1=[targ_dir,filesep,'mri',filesep,'m',targ_fname,targ_ext];
p1= [targ_dir,filesep,'mri',filesep,'p1',targ_fname,targ_ext];
p2= [targ_dir,filesep,'mri',filesep,'p2',targ_fname,targ_ext];
p3= [targ_dir,filesep,'mri',filesep,'p3',targ_fname,targ_ext];
if ~exist(mT1,'file')||~exist(p1,'file')||~exist(p2,'file')||~exist(p3,'file')
fid=fopen([targ_dir,filesep,'list.txt'],'w+');
fprintf(fid,'%s\n',target);
fclose(fid);
cat_batch_cat([targ_dir,filesep,'list.txt'],[opt.script_dir,filesep,'cat_defaults_native.m']);
system(['rm -f ',targ_dir,filesep,'list.txt']);
end
target=[def_dir,filesep,'m',targ_fname,targ_ext];
system(['cp ',p1,' ',def_dir]);
system(['cp ',p2,' ',def_dir]);
system(['cp ',p3,' ',def_dir]);
system(['cp ',mT1,' ',def_dir]);
system(['fslmerge -t ',def_dir,filesep,'segs ',def_dir,filesep,'p*.nii']);
system(['fslmaths ',def_dir,filesep,'segs -Tmean -thr 0.16 -bin ',def_dir,filesep,'T1mask']); 
system(['fslmaths ',def_dir,filesep,'T1mask -mul  ',target,' ',def_dir,filesep,'T1brain']);
system(['fslmaths ',def_dir,filesep,'p2*.nii -thr 0.5 -bin ',def_dir,filesep,'T1brain_wmseg']);
opt.bbr.t1brain=[def_dir,filesep,'T1brain.nii.gz'];
opt.bbr.wmseg=[def_dir,filesep,'T1brain_wmseg.nii.gz'];
system(['rm -rf ',def_dir,filesep,'p*.nii']);
system(['rm -rf ',def_dir,filesep,'segs*']);
if strcmp(opt.cleanup,'yes')
system(['rm -rf ',targ_dir,filesep,'mri report']);
end
end
[tmpdir wm ext]=fileparts(opt.bbr.t1brain);
if strcmp(ext,'.gz');ext=opt.bbr.wmseg(end-6:end);end
if ~strcmp(opt.bbr.wmseg(end-length(ext)-5:end-length(ext)),'_wmseg')
system(['mv ',opt.bbr.wmseg,' ',opt.bbr.wmseg(1:end-length(ext)-6),'_wmseg',ext]);
opt.bbr.wmseg=[opt.bbr.wmseg(1:end-length(ext)-6),'_wmseg',ext];
end
system(['epi_reg --epi=',source,' --t1=',target,' --t1brain=',opt.bbr.t1brain,' --wmseg=',opt.bbr.wmseg,' --out=',bbr_out]);
%system(['rm -f ',def_dir,filesep,'*_wm*.nii.gz']);
system(['rm -f ',bbr_out,'_init.mat']);
%system(['rm -f ',def_dir,filesep,'T1brain.nii.gz']);
end
mat_convert(source,target,[bbr_out,'.mat'],opt.def_out);
end

case 'dartel'
[source_dir,source_fname,source_ext]=fileparts(source);
if ~exist(opt.def_out,'file')
tmp_y=dir([source_dir,filesep,'mri/y_*.nii']);
if isempty(tmp_y)
fid=fopen([source_dir,filesep,'list.txt'],'w+');
fprintf(fid,'%s\n',source);
fclose(fid);
cat_batch_cat([source_dir,filesep,'list.txt'],[opt.script_dir,filesep,'cat_defaults_standard.m']);
wait
system(['rm -f ',source_dir,filesep,'list.txt']);
cmd1=['cp ',source_dir,filesep,'mri',filesep,'wm',source_fname,source_ext,' ',def_dir,'/'];
cmd2=['cp ',source_dir,filesep,'mri',filesep,'y_*.nii ',opt.def_out];
fprintf('%s\n%s\n',cmd1,cmd2);
system(cmd1);
system(cmd2);
end
cmd1=['cp ',source_dir,filesep,'mri',filesep,'wm',source_fname,source_ext,' ',def_dir,'/'];
cmd2=['cp ',source_dir,filesep,'mri',filesep,'y_*.nii ',opt.def_out];
fprintf('%s\n%s\n',cmd1,cmd2);
system(cmd1);
system(cmd2);
if strcmp(opt.cleanup,'yes')
system(['rm -rf ',source_dir, filesep,'mri report']);
end
end
end














