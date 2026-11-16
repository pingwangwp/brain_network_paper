function fiber_split_TH_AAL116(subj,OutPut,Currentdir)

cfg.exclusion_mask='';
cfg.savefibers='yes';
cfg.seed_relation=1;
cfg.fiber_relation='paired';
seed=[OutPut,'/AAL_116_3mm.nii'];

fiber_path=[Currentdir,'/',subj,'/dtk/hardi.trk'];
cfg.outdir=[OutPut,'/fiber_split'];
fiber_summary=bqw_fiber_split(fiber_path,seed,'',cfg);

% load([OutPut,'/fiber_split/hardi_fiber_summary.mat']);
% [bin,net,node] = SingleSubjectgretna_sw_batch_networkanalysis_Scarlett_dtiBinary(fiber_number, 0.05, 0.05, 0.05, 100, 's');
% save([OutPut,filesep,subj,'_network.mat'],'net','node','bin');
% --fiber_paths: fiber file paths,cell array (multiple files) or string (single file)



% --: seeds file paths, cell array (one filepath for each seed) or string (all seeds stored in one file)
% --scalar_paths: diffusion scalar metrics file paths,cell array (multiple files) or string (single file)
% --cfg
%  -cfg.exclusion_mask: mask (filepath string) to exclude fibers ending within
%  -cfg.savefibers:'yes'=save splitted fibers(default),'no'
%  -cfg.seed_relation:vectors (N) or one scalar(for all seeds), defining the seeds relations with fibers,1=end(default);2=pass through
%  -cfg.fiber_relation:'all'=fiber pass(end) all ,  'paired'=fiber pass(end) each paired seeds
%  -cfg.outdir:output directory for splitted fibers and summary, original fiber directory (default)
% --fiber_summary: statistical summary for each splitted fiber 
% 
exit

