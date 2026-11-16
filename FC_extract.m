function FC_extract(Data_name,Path_template,OutputFile)
%     MTC= gretna_mean_tc(Data_path, File_filter,Path_template,1:str2num(RoiIndex));
%     [FC_r,FC_p,FC_z] = gretna_fc_pearson(MTC);
%     save([OutputFile,'.mat'],'FC_p','FC_r','FC_z','MTC');

mask_v=spm_vol(Path_template);
[mask1,~]=spm_read_vols(mask_v);
mask1=reshape(mask1,1,[]);
data_v=spm_vol(Data_name);
[data1,~]=spm_read_vols(data_v);
data1=reshape(data1,[],length(data_v));
data1=data1';
mtc=zeros(length(data_v),max(mask1(:)));
MTC=[];
precent_0voxels=[];
for j=1:max(mask1(:))
    tc=data1(:,find(mask1==j));
    tc(isnan(tc))=0;
    sum_tc=sum(tc);
    tc(:,find(sum_tc==0))=[];
    mtc(:,j)=mean(tc,2);    
    precent_0voxels(j)=length(find(sum_tc==0))/length(find(mask1==j));
end
MTC{1}=mtc;
[fc_r, fc_p] = corrcoef(mtc);
fc_r = fc_r - diag(diag(fc_r));
fc_p = fc_p - diag(diag(fc_p));

%Fisher's r to z transformation   20190325 Scarlett Wang
fc_z=0.5*log((1+fc_r)./(1-fc_r));

FC_r{1} = fc_r;
FC_p{1} = fc_p;
FC_z{1}=fc_z;

save([OutputFile,'.mat'],'FC_p','FC_r','FC_z','MTC','percent_0voxels');
fprintf('Extract %d template FC is done!\n',max(mask1(:)))
exit