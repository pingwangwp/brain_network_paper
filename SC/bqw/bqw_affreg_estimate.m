function affine_map=bqw_affreg_estimate(target,source,opt)
%=======================================================================
if nargin<2
    fprintf('====affine registrating the images using spm_affreg ====\n');
    fprintf('Format: [affine_map]=bqw_affreg_estimate(target,source,opt)\n');
    fprintf('--target: 1 or more templates,cellstring\n');
    fprintf('--source: 1 source image,cellstring\n');
    fprintf('--opt\n--opt.matname:output deformation matname(*_sn.mat)\n');
    fprintf('--opt.smsrc:smooth kernel for source image (mm)\n');
    fprintf('--opt.smref:smooth kernel for target images(mm)\n');
    fprintf('--opt.regtype:regularisation type,''none'',''rigid'',''subj'',''mni''\n');
    fprintf('--opt.fWT:weighted image of target\n');
    fprintf('--opt.fWS:weighted image of source\n');
    fprintf('++++++++++++++written by QinWen at 20181228 +++++++++++++\n');
    return
end
[tmpsrc_dir,tmpsrc,srcext]=fileparts(source{1});
if isempty(tmpsrc_dir);tmpsrc_dir=pwd;end
if strcmp(srcext,'.gz');
gunzip(source{1});
source={tmpsrc_dir,filesep,tmpsrc};
end

[tmptarg_dir,tmptarg,targext]=fileparts(target{1});
if strcmp(targext,'.gz')
for i=1:length(target)
gunzip(target{i});
[tmptarg_dir,tmptarg,targext]=fileparts(target{i});
if isempty(tmptarg_dir);tmptarg_dir=pwd;end
target1{i}=[tmptarg_dir,filesep,tmptarg];
end
target=target1;
end

VSrc = spm_vol(source{1});
for i =1:length(target1)
VTar(i) =spm_vol(target{i});
end

if nargin<3
opt.matname= [tmpsrc_dir,filesep,'affine_sn.mat'];
opt.smsrc  = 8;
opt.smref  = 8;
opt.regtype= 'subj';
opt.fWT    ='';
opt.fWS    ='';
end

if ~isfield(opt,'matname');opt.matname= [tmpsrc_dir,filesep,'affine_sn.mat'];end
if ~isfield(opt,'smsrc');opt.smsrc=8;end
if ~isfield(opt,'smref');opt.smref=8;end
if ~isfield(opt,'regtype');opt.regtype='subj';end
if ~isfield(opt,'fWT');opt.fWT=[];end
if ~isfield(opt,'fWS');opt.fWS=[];end

VSs = spm_smoothto8bit(VSrc,opt.smosrc);
% Rescale images so that globals are better conditioned
VSs.pinfo(1:2,:) = VSs.pinfo(1:2,:)/spm_global(VSs);
for i=1:numel(VTar),
    VTs(i) = spm_smoothto8bit(VTar(i),opt.smoref);
    VTs(i).pinfo(1:2,:) = VTs(i).pinfo(1:2,:)/spm_global(VTs(i));
end;
%----------------------------------------- 
opt.sep=max(opt.smoref,opt.smosrc);
opt.sep=max(opt.sep,max(sqrt(sum(VTar(1).mat(1:3,1:3).^2))));
opt.sep=max(opt.sep,max(sqrt(sum(VSrc(1).mat(1:3,1:3).^2))));
M = eye(4);
[M,scal]  = spm_affreg(VTs, VSs, opt, M);
%-----------------------------------------
opt.sep = opt.sep/2;
[M,scal]   = spm_affreg(VTs,  VSs, opt, M,scal);
%-----------------------------------------
fprintf('Fine Affine Registration 2..\n'); %%
opt.sep = opt.sep/2;
[M,scal]   = spm_affreg(VTs,  VSs, opt, M,scal);
%-----------------------------------------
k=(opt.sep/max(abs(VSrc.mat(1,1)),abs(VTar.mat(1,1))));
if k>2
    fprintf('Fine Affine Registration 3.\n');
     opt.sep = opt.sep/2;
     [M,scal]   = spm_affreg(VTs,  VSs, opt, M,scal);
end
Affine  = inv(VTar(1).mat\M*VSrc.mat);
params = struct('Affine',Affine, 'Tr',[], 'VF',VSrc, 'VG',VTar, 'flags',opt);
params.flags.version = 'bqw_affine_estimate.m 2018/12/28';
params.flags.date    = date;
save(opt.matname,'-struct','params');
fprintf('Finish Affine coregistration:\n--source:%s\n--target:%s\n', source{1},target{1});
affine_map=opt.matname;

if strcmp(targext,'.gz')
for i=1:length(target)
system(['rm -f ',target{i}]);
end
end

if strcmp(srcext,'.gz')
system(['rm -f ',source{i}]);
end



