function fiber_summary=bqw_fiber_split(fiber_paths,seeds,scalar_paths,cfg)
% Format: fiber_summary=bqw_fiber_split(fiber_paths,seeds,cfg)
% Split fiber branches between seeds
% --fiber_paths: fiber file paths,cell array (multiple files) or string (single file)
% Note: the fiber file format can be '.trk','.trk.gz', or '.mat'(dsi_studio).
% --seeds: seeds file paths, cell array (one filepath for each seed) or string (all seeds stored in one file).
% --scalar_paths: diffusion scalar metrics file paths,cell array (multiple files) or string (single file)
% --cfg
%  -cfg.exclusion_mask: mask (filepath string) to exclude fibers ending within
%  -cfg.savefibers:'yes'=save splitted fibers(default),'no'
%  -cfg.seed_relation:vectors (Nseeds) or one scalar(for all seeds) defining the seeds relations with fibers,1=end(default);2=pass through
%  -cfg.fiber_relation: 'all'=fiber pass(end) all seeds,  'paired'=fiber pass(end) each paired seeds, 'one'=fiber pass(end) one seed;
%  -cfg.outdir:output directory for fibers and summary, original fiber directory (default)
% --fiber_summary: statistical summary for each splitted fiber
% --------------------Written by QinWen 20180424---------------------------
if nargin<2
    fprintf('=============Split fiber branches between seeds =============\n');
    fprintf('Format: fib_summary=bqw_fiber_split(fiber_path,seeds,cfg)\n');
    fprintf('--fiber_paths: fiber file paths,cell array (multiple files) or string (single file)\n');
    fprintf('--seeds: seeds file paths, cell array (one filepath for each seed) or string (all seeds stored in one file)\n');
    fprintf('--scalar_paths: diffusion scalar metrics file paths,cell array (multiple files) or string (single file)\n');
    fprintf('--cfg\n -cfg.exclusion_mask: mask (filepath string) to exclude fibers ending within\n');
    fprintf(' -cfg.savefibers:''yes''=save splitted fibers(default),''no''\n');
    fprintf(' -cfg.seed_relation:vectors (Nseeds) or one scalar(for all seeds), defining the seeds relations with fibers,1=end(default);2=pass through\n');
    fprintf(' -cfg.fiber_relation:''all''=fiber pass(end) all seeds,  ''paired''=fiber pass(end) each paired seeds,''one''=fiber pass(end) one seed\n');
    fprintf(' -cfg.outdir:output directory for splitted fibers and summary, original fiber directory (default)\n');
    fprintf('--fiber_summary: statistical summary for each splitted fiber \n');
    fprintf('------------------Written by QinWen 20180424----------------------\n');
    return
end
if nargin==4
    if ~isfield(cfg,'exclusion_mask');cfg.exclusion_mask=''; end
    if ~isfield(cfg,'savefibers'); cfg.savefibers='yes';end
    if ~isfield(cfg,'seed_relation');cfg.seed_relation=[];end
    if ~isfield(cfg,'fiber_relation');cfg.fiber_relation='all';end
    if ~isfield(cfg,'outdir');cfg.outdir='';end
end
if nargin<4
    cfg.exclusion_mask='';
    cfg.savefibers='yes';
    cfg.seed_relation=[];
    cfg.fiber_relation='all';
    cfg.outdir='';
end
if nargin<3
    scalar_paths='';
end

%% read the seeds
[seed_img seed_vol]=bqw_read_nii(seeds);
[seed_dir,seedname,ext]=fileparts(seed_vol(1).fname);
if strcmp(ext,'.gz')
    [seed_dir,seedname]=fileparts([seed_dir,filesep,seedname]);
end

msize=size(seed_img);
% check if the seeds are integer
k=unique(seed_img);
k(k==0)=[];
if any(mod(k,1))
    error('The seeds images must integer,please check');
end
% merge multiple seeds images into one
seed_label{1,1}='seed_name';
seed_label{1,2}='seed_num';
seed_label{1,3}='end/pass(1/2)';
if length(msize)==4
    seed_img(seed_img~=0)=1;
    tmpimg=zeros(msize(1:3));
    for m=1:msize(4)
        [tmpdir,fname,ext]=fileparts(seed_vol(m).fname);
        if strcmp(ext,'.gz')
            [tmpdir,fname]=fileparts([tmpdir,filesep,fname]);
        end        
        seed_label{2,1}{m,1}=fname;
        seed_label{2,2}(m,1)=m;
        idx=seed_img(:,:,:,m)==1;
        tmpimg(idx)=m;
    end
    seed_img=tmpimg;
    seed_num=unique(seed_img);
    seed_num(seed_num==0)=[];
else
    seed_label{2,1}{1,1}=seed_vol.fname;
    seed_num=unique(seed_img);
    seed_num(seed_num==0)=[];
    seed_label{2,2}{1,1}=seed_num;
end
Nseeds=length(seed_num);
for n=1:Nseeds
    seed_idx(n).idx=find(seed_img==seed_num(n));
end
seed_mask=find(seed_img>0);
if isempty(cfg.seed_relation)
    cfg.seed_relation=ones(Nseeds,1);% default is endpoints
end

if length(cfg.seed_relation)==1;
    cfg.seed_relation=repmat(cfg.seed_relation,Nseeds,1);
end
seed_label{2,3}=cfg.seed_relation;

%% read the exclusion mask
if ~isempty(cfg.exclusion_mask)
    [ex_img ex_vol]=bqw_read_nii(cfg.exclusion_mask);
    ex_img(ex_img~=0)=1;
    if sum(ex_vol.dim==msize(1:3))~=3
        error('Mismatch betwen exclusion_mask [%d %d %d] and seed dimensions[%d %d %d]',mvol.dim,msize(1:3));
    end
    ex_idx=find(ex_img~=0);
else
    ex_idx=[];
end

%% read the diffusion scalars
if ~isempty(scalar_paths)
    if isstr(scalar_paths)
        tmp={scalar_paths};
        scalar_paths=tmp;
    end
    [scal_img,scal_vol]=bqw_read_nii(scalar_paths);
    if sum(scal_vol(1).dim==msize(1:3))~=3
        error('Mismatch betwen diffusion scalars [%d %d %d] and seed dimensions[%d %d %d]',scal_vol.dim,msize(1:3));
    end
    for sc=1:length(scalar_paths)        
        [tmpdir,fname,ext]=fileparts(scalar_paths{sc});
        if strcmp(ext,'.gz')
            [tmpdir,fname]=fileparts([tmpdir,filesep,fname]);
        end
        scal_name{sc,1}=fname;        
    end
end

%% read the fibers
if isstr(fiber_paths);
    tmp={fiber_paths};
    fiber_paths=tmp;
end
for p=1:length(fiber_paths)
    tic
    fprintf('\n====Split fiber branches between seeds: %s\n',fiber_paths{p});
    [fiber_dir,trkname,ext]=fileparts(fiber_paths{p});
    if strcmp(ext,'.gz')
        [fiber_dir,trkname]=fileparts([fiber_dir,filesep,trkname]);
    end
    
    if isempty(cfg.outdir);cfg.outdir=[fiber_dir,filesep,'fiber_branches'];end
    if ~exist(cfg.outdir);mkdir(cfg.outdir);end
    if strcmp(ext,'.gz')||strcmp(ext,'.trk')
        [fib hdr]=bqw_read_trk(fiber_paths{p});
        fib_num=length(fib);
        fdim=hdr.dim;
        if sum(fdim==msize(1:3))~=3
            error('Mismatch betwen fiber[%d %d %d] and seed dimensions[%d %d %d]',fdim,msize(1:3));
        end
    elseif strcmp(ext,'.mat')
        fib=load(fiber_paths{p});
        fib_num=length(fib.length);
    else
        error('Unsupported trk type ''%s''',ext);
    end
    %% extract fiber pass(end) all seeds
    if strcmp(cfg.fiber_relation,'all')
        if strcmp(ext,'.mat')
            branch_trk.tracts=[];
        end
        branch_img=zeros(msize(1:3));
        k=0;flength=[];
        for f=1:fib_num
            if strcmp(ext,'.gz')||strcmp(ext,'.trk')
                fib_length=fib(f).nPoints;
                fib_coord_vox=double(fib(f).coord./repmat(hdr.voxel_size,fib(f).nPoints,1));% convert mm to voxel coordinates
            else
                idx=sum(fib.length(1:f-1))+1:sum(fib.length(1:f));
                fib_coord_vox=fib.tracts(:,idx);
                fib_coord_vox=fib_coord_vox';
                fib_length=fib.length(f);
            end
            fib_coord1=[];
            fib_coord1(:,1)=fib_coord_vox(:,1);
            fib_coord1(:,2)=msize(2)-fib_coord_vox(:,2);
            fib_coord1(:,3)=fib_coord_vox(:,3);
            fib_coord1=ceil(fib_coord1);
            fib_idx=coord2scalar(fib_coord1,msize(1:3));
            % exclude fibers that pass into the exclusion masks
            is_exclude=intersect(fib_idx,ex_idx);
            fib_tag=1;
            if ~sum(is_exclude)
                for n=1:Nseeds
                    if cfg.seed_relation(n)==2
                        is_seed=intersect(fib_idx,seed_idx(n).idx);
                    elseif cfg.seed_relation(n)==1
                        endpoint=fib_idx([1,end]);
                        is_seed=intersect(endpoint,seed_idx(n).idx);
                    end
                    if ~sum(is_seed)
                        fib_tag=0;
                        break
                    end
                end
                
                if fib_tag
                    k=k+1;
                    if strcmp(ext,'.mat')
                        branch_trk.length(k) = fib_length;
                        branch_trk.tracts=[branch_trk.tracts,fib_coord_vox'];
                        %                         branch_trk.tracts    = [branch_trk.tracts,fib_coord_vox'];
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        branch_trk(k,1).nPoints =fib_length;
                        branch_trk(k,1).coord=fib(f).coord;
                        if hdr.n_properties
                            branch_trk(k,1).props=fib(f).props;
                        end
                    end
                    flength(k,1)= fib_length;
                    branch_img(fib_idx) = branch_img(fib_idx)+1;
                end
            end
            if mod(f,1000)==0
                %                 fprintf('fiber %d - %d \n',fib_num,f);
                fprintf('.');
            end
        end
        %% write the fibers and summary
        % save as trk file
        if strcmp(ext,'.gz')||strcmp(ext,'.trk')
            hdr.trkpath=[cfg.outdir,filesep,trkname,'_',seedname,'.trk'];
            hdr.n_count=length(branch_trk);
            bqw_write_trk(hdr,branch_trk);
        elseif strcmp(ext,'.mat')
            % save as dsi_studio mat file
            outpath=[cfg.outdir,filesep,trkname,'_',seedname,'.mat'];
            save(outpath,'-struct','branch_trk','-v4');
        end
        % save as nifti file
        fibvol=seed_vol(1);
        fibvol.fname=[cfg.outdir,filesep,trkname,'_',seedname,'.nii'];
        fibvol.dt=[4,0];
        bqw_write_nii(fibvol,branch_img);
        % save fiber summary
        fiber_summary.Nfib=k;
        fiber_summary.seed_label=seed_label;
        % fiber length %revised at 20180528
        fiber_summary.fiber_length= mean(flength);
        if ~isempty(scalar_paths)
            for sc=1:length(scal_name)
                tmpsc=scal_img(:,:,:,sc).*branch_img;
                mean_scal=sum(tmpsc(:))/sum(branch_img(:));
                eval(['fiber_summary.',scal_name{sc},'=mean_scal;']);
            end
        end
        sumpath=[cfg.outdir,filesep,trkname,'_fiber_summary.mat'];
        save(sumpath,'-struct','fiber_summary');
    end
    %% extract fiber pass(end) each pair of seeds
    if strcmp(cfg.fiber_relation,'paired')
        fprintf('  --identifing fibers: ');
        k=1;
        for f=1:fib_num
            if strcmp(ext,'.gz')||strcmp(ext,'.trk')
                fib_length=fib(f).nPoints;
                fib_coord_vox=double(fib(f).coord./repmat(hdr.voxel_size,fib(f).nPoints,1));% convert mm to voxel coordinates
            else
                idx=sum(fib.length(1:f-1))+1:sum(fib.length(1:f));
                fib_coord_vox=fib.tracts(:,idx);
                fib_coord_vox=fib_coord_vox';
                fib_length=fib.length(f);
            end
            fib_coord1=[];
            fib_coord1(:,1)=fib_coord_vox(:,1);
            fib_coord1(:,2)=msize(2)-fib_coord_vox(:,2);
            fib_coord1(:,3)=fib_coord_vox(:,3);
            fib_coord1=ceil(fib_coord1);
            dbstop if error
            fib_idx=coord2scalar(fib_coord1,msize(1:3));
            % exclude fibers that pass into the exclusion masks
            is_exclude=intersect(fib_idx,ex_idx);
            if sum(is_exclude)
                continue
            end
            pass_id=intersect(fib_idx,seed_mask);
            endpoint=fib_idx([1,end]);
            end_id=intersect(endpoint,seed_mask);
            if ~isempty([pass_id; end_id])
                % find ending seeds
                seed_end=seed_img(end_id);
                end_num=unique(seed_end);
                seed_pass=seed_img(pass_id);
                pass_num=unique(seed_pass);
                if length(pass_num)<2
                    continue
                end
                pass_stat=histc(seed_pass,pass_num);
                [~,id]=sort(pass_stat);
                pass_max2_id=id(end-1:end);% find two max seed
                pass_num_max2=pass_num(pass_max2_id);
                
                [~,orig_seed_num_id]=ismember(pass_num_max2,seed_num);
                seed_relation=cfg.seed_relation(orig_seed_num_id);
                if length(end_num)==2 % two end seeds are also pass
                    [~,seed_id]=ismember(end_num,seed_num);
                    branches.seed_pair(k,1:2)=seed_id;
                    if  strcmp(ext,'.mat')
                        branches.fib_coord_vox{k,1}=fib_coord_vox;
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        branches.fib_coord_mm{k,1}=fib(f).coord;
                        if hdr.n_properties
                            branches.props{k,1}=fib(f).props;
                        end
                    end
                    branches.fib_idx{k,1}=fib_idx;
                    branches.fib_num(k,1)=length(fib_idx);
                    k=k+1;
                elseif length(end_num)==1
                    if sum(seed_relation)>2 %include fiber with at least one end point
                        tmp_num(1)=end_num;
                        pass1=max(pass_num_max2(pass_num_max2~=end_num));% another node is the pass seed with max fiber overlapping and excluding the end_num
                        tmp_num(2)=pass1;
                        [~,seed_id]=ismember(sort(tmp_num),seed_num);
                        branches.seed_pair(k,1:2)=sort(seed_id);
                        if  strcmp(ext,'.mat')
                            branches.fib_coord_vox{k,1}=fib_coord_vox;
                        elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                            branches.fib_coord_mm{k,1}=fib(f).coord;
                            if hdr.n_properties
                                branches.props{k,1}=fib(f).props;
                            end
                        end
                        branches.fib_idx{k,1}=fib_idx;
                        branches.fib_num(k,1)=length(fib_idx);
                        k=k+1;
                    end
                elseif length(end_num)==0
                    if sum(seed_relation)==4 %include fiber with at least one end point
                        branches.seed_pair(k,1:2)=orig_seed_num_id;
                        if  strcmp(ext,'.mat')
                            branches.fib_coord_vox{k,1}=fib_coord_vox;
                        elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                            branches.fib_coord_mm{k,1}=fib(f).coord;
                            if hdr.n_properties
                                branches.props{k,1}=fib(f).props;
                            end
                        end
                        branches.fib_idx{k,1}=fib_idx;
                        branches.fib_num(k,1)=length(fib_idx);
                        k=k+1;
                    end
                end
            end
            if mod(f,1000)==0
                fprintf('.');
            end
        end
        %% summarize and output
        fprintf('\n  --extracting branches and scalars: ');
        fiber_summary.fiber_number=zeros(Nseeds);
        fiber_summary.fiber_density=zeros(Nseeds);
        fiber_summary.fiber_length=zeros(Nseeds);% revised at 20180528
        fiber_summary.fiber_density_LenCorr=zeros(Nseeds);
        if ~isempty(scalar_paths)
            for sc=1:length(scal_name)
                eval(['fiber_summary.mean_',scal_name{sc},'=zeros(Nseeds);']);
            end
        end
        if exist('branches')
            seed_pairs=unique(branches.seed_pair,'rows');
            for s=1:size(seed_pairs,1)
                if mod(s,100)==0
                    fprintf('.');
                end
                pair1=seed_pairs(s,:);
                [~,pair_idx]=ismember(branches.seed_pair,pair1,'rows');
                sub_idx=find(pair_idx);
                nfib=sum(pair_idx);
                %                 ave_leng=mean(branches.fib_num(sub_idx));% used to threshold out too long or short sp
                if strcmp(ext,'.mat')
                    branch_trk.tracts=[];
                end
                branch_img=zeros(msize(1:3));
                flength=[];
                kk=1;
                for nf=1:nfib
                    if strcmp(ext,'.mat')
                        fib_coord_vox=branches.fib_coord_vox{sub_idx(nf),1};
                        nPoints=size(fib_coord_vox,1);
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        fib_coord_mm=branches.fib_coord_mm{sub_idx(nf),1};
                        nPoints=size(fib_coord_mm,1);
                        if hdr.n_properties
                            props=branches.props{sub_idx(nf),1};
                        end
                    end
                    flength(nf,1)=nPoints;
                    fib_idx=branches.fib_idx{sub_idx(nf),1};
                    %  if strcmp(cfg.savefibers,'yes')
                    if strcmp(ext,'.mat')
                        branch_trk.length(kk) = nPoints;
                        
                        branch_trk.tracts     = [branch_trk.tracts,fib_coord_vox'];
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        branch_trk(kk,1).nPoints =nPoints;
                        
                        branch_trk(kk,1).coord=fib_coord_mm;
                        if hdr.n_properties
                            branch_trk(kk,1).props= props;
                        end
                    end
                    branch_img(fib_idx) = branch_img(fib_idx)+1;
                    % end
                    kk=kk+1;
                end
                %% calculate connectivity properties
                % fiber number
                fiber_summary.fiber_number(pair1(1),pair1(2))=nfib;%
                % fiber density  nfib/[mean seeds voxels]
                nvox_seed1=length(seed_idx(pair1(1)).idx);
                nvox_seed2=length(seed_idx(pair1(2)).idx);
                mvox=mean([nvox_seed1,nvox_seed2]);
                fiber_summary.fiber_density(pair1(1),pair1(2))=nfib/mvox;%
                %fiber length. revised at 20180528
                fiber_length= mean(flength);
                fiber_summary.fiber_length(pair1(1),pair1(2))=fiber_length;
                %fiber density corrected for fiber length: revised at 20180528
                fiber_summary.fiber_density_LenCorr(pair1(1),pair1(2))=nfib/mvox/fiber_length;
                % diffusion scalars (weighted by fiber number of voxels)
                if ~isempty(scalar_paths)
                    for sc=1:length(scal_name)
                        tmpsc=scal_img(:,:,:,sc).*branch_img;
                        mean_scal=sum(tmpsc(:))/sum(branch_img(:));
                        eval(['fiber_summary.mean_',scal_name{sc},'(pair1(1),pair1(2))=mean_scal;']);
                    end
                end
                %% write the fibers
                % save as trk file
                if strcmp(cfg.savefibers,'yes')
                    if strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        hdr.trkpath=[cfg.outdir,filesep,trkname,'_',seedname,'_',num2str(pair1(1)),'-',num2str(pair1(2)),'.trk'];
                        hdr.n_count=length(branch_trk);
                        bqw_write_trk(hdr,branch_trk);
                    elseif strcmp(ext,'.mat')
                        % save as dsi_studio mat file
                        outpath=[cfg.outdir,filesep,trkname,'_',seedname,'_',num2str(pair1(1)),'-',num2str(pair1(2)),'.mat'];
                        save(outpath,'-struct','branch_trk','-v4');
                    end
                    % save as nifti file
                    fibvol=seed_vol(1);
                    fibvol.fname=[cfg.outdir,filesep,trkname,'_',seedname,'_',num2str(pair1(1)),'-',num2str(pair1(2)),'.nii'];
                    fibvol.dt=[4,0];
                    bqw_write_nii(fibvol,branch_img);
                    clear branch_trk
                end
            end
        end
        % save fiber summary
        fiber_summary.seed_label=seed_label;
        sumpath=[cfg.outdir,filesep,trkname,'_fiber_summary.mat'];
        save(sumpath,'-struct','fiber_summary');
    end
    
    %% extract fiber pass(end) one certain seed
    if strcmp(cfg.fiber_relation,'one')
        fprintf('  --identifing fibers: ');
        k=1;
        for f=1:fib_num
            if strcmp(ext,'.gz')||strcmp(ext,'.trk')
                fib_length=fib(f).nPoints;
                fib_coord_vox=double(fib(f).coord./repmat(hdr.voxel_size,fib(f).nPoints,1));% convert mm to voxel coordinates
            else
                idx=sum(fib.length(1:f-1))+1:sum(fib.length(1:f));
                fib_coord_vox=fib.tracts(:,idx);
                fib_coord_vox=fib_coord_vox';
                fib_length=fib.length(f);
            end
            fib_coord1=[];
            fib_coord1(:,1)=fib_coord_vox(:,1)+1;
            fib_coord1(:,2)=msize(2)-fib_coord_vox(:,2);
            fib_coord1(:,3)=fib_coord_vox(:,3)+1;
            fib_coord1=round(fib_coord1);
            fib_idx=coord2scalar(fib_coord1,msize(1:3));
            % exclude fibers that pass into the exclusion masks
            is_exclude=intersect(fib_idx,ex_idx);
            if sum(is_exclude)
                continue
            end
            pass_id=intersect(fib_idx,seed_mask);
            endpoint=fib_idx([1,end]);
            end_id=intersect(endpoint,seed_mask);
            if ~isempty([pass_id; end_id])
                % find ending seeds
                seed_end=seed_img(end_id);
                end_num=unique(seed_end);
                seed_pass=seed_img(pass_id);
                pass_num=unique(seed_pass);
                pass_stat=histc(seed_pass,pass_num);
                %                 [~,id]=sort(pass_stat);
                %                 pass_max2_id=id(end);% find max seed
                [~,pass_max2_id]=max(pass_stat);   % find max seed revised by qinwen 20180608
                pass_num_max2=pass_num(pass_max2_id);
                [~,orig_seed_num_id]=ismember(pass_num_max2,seed_num);
                seed_relation=cfg.seed_relation(orig_seed_num_id);
                
                if seed_relation==1
                    if ~isempty(end_num)%include fiber with end in the seed
                        for e=1:length(end_num)
                            [~,seed_id]=ismember(end_num(e),seed_num);
                            branches.seed_pair(k,1)=seed_id;
                            if  strcmp(ext,'.mat')
                                branches.fib_coord_vox{k,1}=fib_coord_vox;
                            elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                                branches.fib_coord_mm{k,1}=fib(f).coord;
                                if hdr.n_properties
                                    branches.props{k,1}=fib(f).props;
                                end
                            end
                            branches.fib_idx{k,1}=fib_idx;
                            branches.fib_num(k,1)=length(fib_idx);
                            k=k+1;
                        end
                    end
                elseif seed_relation==2 %include fiber with pass the seed
                    branches.seed_pair(k,1)=orig_seed_num_id;
                    if  strcmp(ext,'.mat')
                        branches.fib_coord_vox{k,1}=fib_coord_vox;
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        branches.fib_coord_mm{k,1}=fib(f).coord;
                        if hdr.n_properties
                            branches.props{k,1}=fib(f).props;
                        end
                    end
                    branches.fib_idx{k,1}=fib_idx;
                    branches.fib_num(k,1)=length(fib_idx);
                    k=k+1;
                end
            end
            
            if mod(f,1000)==0
                fprintf('.');
            end
        end
        %     end
        %% summarize and output
        fprintf('\n  --extracting branches and scalars: ');
        fiber_summary.fiber_number=zeros(Nseeds,1);
        fiber_summary.fiber_length=zeros(Nseeds,1);% revised at 20180528
        if ~isempty(scalar_paths)
            for sc=1:length(scal_name)
                eval(['fiber_summary.mean_',scal_name{sc},'=zeros(Nseeds,1);']);
            end
        end
        if exist('branches')
            seed_pairs=unique(branches.seed_pair,'rows');
            for s=1:size(seed_pairs,1)
                if mod(s,100)==0
                    fprintf('.');
                end
                pair1=seed_pairs(s,:);
                [~,pair_idx]=ismember(branches.seed_pair,pair1,'rows');
                sub_idx=find(pair_idx);
                nfib=sum(pair_idx);
                if strcmp(ext,'.mat')
                    branch_trk.tracts=[];
                end
                branch_img=zeros(msize(1:3));
                flength=[];
                kk=1;
                for nf=1:nfib
                    if strcmp(ext,'.mat')
                        fib_coord_vox=branches.fib_coord_vox{sub_idx(nf),1};
                        nPoints=size(fib_coord_vox,1);
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        fib_coord_mm=branches.fib_coord_mm{sub_idx(nf),1};
                        nPoints=size(fib_coord_mm,1);
                        if hdr.n_properties
                            props=branches.props{sub_idx(nf),1};
                        end
                    end
                    flength(nf,1)=nPoints;
                    fib_idx=branches.fib_idx{sub_idx(nf),1};
                    %  if strcmp(cfg.savefibers,'yes')
                    if strcmp(ext,'.mat')
                        branch_trk.length(kk) = nPoints;
                        branch_trk.tracts     = [branch_trk.tracts,fib_coord_vox'];
                    elseif strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        branch_trk(kk,1).nPoints =nPoints;
                        branch_trk(kk,1).coord=fib_coord_mm;
                        if hdr.n_properties
                            branch_trk(kk,1).props= props;
                        end
                    end
                    branch_img(fib_idx) = branch_img(fib_idx)+1;
                    % end
                    kk=kk+1;
                end
                %% calculate connectivity properties
                % fiber number
                fiber_summary.fiber_number(pair1)=nfib;%
                % seed volume
                %             nvox_seed1=length(seed_idx(pair1).idx);
                %             fiber_summary.seed_vol(pair1)=nfib/nvox_seed1;%
                %fiber length. revised at 20180528
                fiber_length= mean(flength);
                fiber_summary.fiber_length(pair1)=fiber_length;
                % diffusion scalars (weighted by fiber number of voxels)
                if ~isempty(scalar_paths)
                    for sc=1:length(scal_name)
                        tmpsc=scal_img(:,:,:,sc).*branch_img;
                        mean_scal=sum(tmpsc(:))/sum(branch_img(:));
                        eval(['fiber_summary.mean_',scal_name{sc},'(pair1)=mean_scal;']);
                    end
                end
                %% write the fibers
                % save as trk file
                if strcmp(cfg.savefibers,'yes')
                    if strcmp(ext,'.gz')||strcmp(ext,'.trk')
                        hdr.trkpath=[cfg.outdir,filesep,trkname,'_',seedname,'_',num2str(pair1),'.trk'];
                        hdr.n_count=length(branch_trk);
                        bqw_write_trk(hdr,branch_trk);
                    elseif strcmp(ext,'.mat')
                        % save as dsi_studio mat file
                        outpath=[cfg.outdir,filesep,trkname,'_',seedname,'_',num2str(pair1),'.mat'];
                        save(outpath,'-struct','branch_trk','-v4');
                    end
                    % save as nifti file
                    fibvol=seed_vol(1);
                    fibvol.fname=[cfg.outdir,filesep,trkname,'_',seedname,num2str(pair1),'.nii'];
                    fibvol.dt=[4,0];
                    bqw_write_nii(fibvol,branch_img);
                    clear branch_trk
                end
            end
        end
        % save fiber summary
        fiber_summary.seed_label=seed_label;
        sumpath=[cfg.outdir,filesep,trkname,'_fiber_summary.mat'];
        save(sumpath,'-struct','fiber_summary');
    end
    fprintf('\n==Finish splite fibers,spend %0.0f seconds\n',toc);
end