function SingleSubjectTopoProperties_sparsity(inputpath,inputfile,outputpath,thr)
tic

%% Modifying the path here !!!!!!!!!!!!!!
% ****************************************************************************************
addpath(genpath(['/path/GRETNA-2.0.0_release']))

% ****************************************************************************************
%%
if ~isdir(outputpath)
    mkdir(outputpath)
end
if nargin<4
    thr=0.05:0.05:0.5;    %sparsity 0.05:0.05:0.5
end

w=load([inputpath,inputfile]);
A1=w.FC_z;
A1=A1{1,1};
A1(find(A1<0))=0;    %positive network;
A1=A1(1:90,1:90);    %%%%AAL90
A=[];
fprintf('Generating RealNets...\n');
badfile=[outputpath,'unusable/'];
if ~isdir(badfile)
    mkdir(badfile)
end
for i=1:length(thr)
    [B, ~] = gretna_R2b(A1, 's', thr(i));
    A2=A1.*B;
    k=isnan(A2);
    sum_nan=sum(k(:));
    if sum_nan>0
        save([badfile,inputfile],'inputfile')
        return
    end
   
    A{i}=A2;
end
deltas=(thr(end)-thr(1))/(length(thr)-1);
%% GEN RandNets
% num_RandNet=1000;
% Rand=[];
% fprintf('Generating %d RandNets>>>\n',num_RandNet);
% trand=tic;
% for i=1:num_RandNet
%     for j=1:length(thr)
%         if length(find(A{j}==0))>length(A{j})
%             Rand{i,j}=gretna_gen_random_network1_weight(A{j});     %if A is not full connected network, use rand_network1
%         else
%             Rand{i,j}=gretna_gen_random_network2_weight(A{j});      %if A is full connected network, use rand_network2
%         end
%     end
% end
num_RandNet=1000;
Rand=[];
fprintf('Generating %d RandNets>>>\n',num_RandNet);
trand=tic;
% OutputFile=[NetPath,'RandNet_',inputfile(1:end-4),'.mat'];
% if exist(OutputFile,'file')
%     delete(OutputFile)
% end

Rand=gretna_RUN_GenRandNet1(A, 2, num_RandNet);
fprintf('RandNets finished!>>>>')
toc(trand)
fprintf('\n')
%% SmallWorld and cp lp
fprintf('Calculating Small World of %s>>>>',inputfile)
tsm=tic;
output_sm=[outputpath,'SmallWorld/'];
if ~isdir(output_sm)
    mkdir(output_sm)
end
outputfilesm=[output_sm,'SmallWorld_',inputfile(1:end-4),'.mat'];
gretna_RUN_SmallWorld1(A, Rand,outputfilesm ,2, 1, deltas)
output_cp=[outputpath,'ClusterCoef/'];
if ~isdir(output_cp)
    mkdir(output_cp)
end
output_lp=[outputpath,'ShortestPath/'];
if ~isdir(output_lp)
    mkdir(output_lp)
end
for i=1:length(thr)
    [Cp(1,i),Cp_nodal(:,i)] = gretna_node_clustcoeff_weight(A{i},2);
    [Lp(1,i),Lp_nodal(:,i)] = gretna_node_shortestpathlength_weight(A{i});
end
% for i=1:length(Rand)
%     for j=1:length(thr)
%         Cp_rand(i,j)=gretna_node_clustcoeff_weight(Rand{i,j},2);
%         Lp_rand(i,j)=gretna_node_shortestpathlength_weight(Rand{i,j});
%     end
% end
% Gamma=Cp./mean(Cp_rand);
% Lambda=Lp./mean(Lp_rand);
% Sigma=Gamma./Lambda;
% 
aCp=(sum(Cp)-sum(Cp([1 end]))/2)*deltas;     %AUC
aLp=(sum(Lp)-sum(Lp([1 end]))/2)*deltas;
% aGamma=(sum(Gamma)-sum(Gamma([1 end]))/2)*deltas;
% aLambda=(sum(Lambda)-sum(Lambda([1 end]))/2)*deltas;
% aSigma=(sum(Sigma)-sum(Sigma([1 end]))/2)*deltas;
[m,n]=size(Cp_nodal);
for i=1:m
    aCp_nodal(1,i)=(sum(Cp_nodal(i,:))-sum(Cp_nodal(i,[1 end]))/2)*deltas;
    aLp_nodal(1,i)=(sum(Lp_nodal(i,:))-sum(Lp_nodal(i,[1 end]))/2)*deltas;
end
% save([output_sm,'SmallWorld_',inputfile(1:end-4),'.mat'],'Cp','Lp','Gamma','Lambda','Sigma','aCp','aLp','aGamma','aLambda','aSigma')
save([output_cp,'CpNodal_',inputfile(1:end-4),'.mat'],'Cp_nodal','aCp_nodal')
save([output_lp,'LpNodal_',inputfile(1:end-4),'.mat'],'Lp_nodal','aLp_nodal')
toc(tsm)
fprintf('\n')
%% NetworkEfficency (global and nodal)
fprintf('Calculating Network Efficency of %s>>>>',inputfile)
te=tic;
output_ne=[outputpath,'NetworkEfficency/'];
if ~isdir(output_ne)
    mkdir(output_ne)
end
for i=1:length(thr)
    [Eg(1,i),Egnodal(:,i)]=gretna_node_global_efficiency_weight(A{i});
    [Eloc(1,i),Elocnodal(:,i)]=gretna_node_local_efficiency_weight(A{i});
end
aEg=(sum(Eg)-sum(Eg([1 end]))/2)*deltas;
aEloc=(sum(Eloc)-sum(Eloc([1 end]))/2)*deltas;
[m,n]=size(Egnodal);
for i=1:m
    aEgnodal(1,i)=(sum(Egnodal(i,:))-sum(Egnodal(i,[1 end]))/2)*deltas;
    aElocnodal(1,i)=(sum(Elocnodal(i,:))-sum(Elocnodal(i,[1 end]))/2)*deltas;
end
save([output_ne,'NetworkEfficency_',inputfile(1:end-4),'.mat'],'Eg','Eloc','Egnodal','Elocnodal','aEg','aEloc','aEgnodal','aElocnodal')
toc(te)
fprintf('\n')
%% Assortativity
% fprintf('Calculating Assortativity of %s>>>>',inputfile)
% tr=tic;
% output_r=[outputpath,'Assortativity/'];
% if ~isdir(output_r)
%     mkdir(output_r)
% end
% for i=1:length(thr)
%     r1=gretna_assortativity_weight(A{i},0);
%     r(i)=r1.real;
% end
% for i=1:length(Rand)
%     for j=1:length(thr)
%         rr=gretna_assortativity_weight(Rand{i,j},0);
%         rrand(i,j)=rr.real;
%     end
% end
% rzscore=(r- mean(rrand))./(std(rrand));
% ar=(sum(r)-sum(r([1 end]))/2)*deltas;
% arzscore=(sum(rzscore)-sum(rzscore([1 end]))/2)*deltas;
% save([output_r,'Assortativity_',inputfile(1:end-4),'.mat'],'r','rzscore','ar','arzscore')
% toc(tr)
% fprintf('\n')
%% Synchronization
% fprintf('Calculating Synchronization of %s>>>>',inputfile)
% ts=tic;
% output_s=[outputpath,'Synchronization/'];
% if ~isdir(output_s)
%     mkdir(output_s)
% end
% s=gretna_synchronization_weight(A,0);
% S=s.real;
% for i=1:length(Rand)
%     ss=gretna_synchronization_weight(Rand{i,1},0);
%     Srand(i)=ss.real;
% end
% Szscore=(S-mean(Srand(~isnan(Srand))))/std(Srand(~isnan(Srand)));
% save([output_s,'Synchronization_',inputfile],'S','Szscore')
% toc(ts)
%% Hierarchy
% fprintf('Calculating Hierarchy of %s>>>>',inputfile)
% tb=tic;
% output_b=[outputpath,'Hierarchy/'];
% if ~isdir(output_b)
%     mkdir(output_b)
% end
% for i=1:length(thr)
%     beta=gretna_hierarchy_weight(A{i},0);
%     b(i)=beta.real;
% end
% for i=1:length(Rand)
%     for j=1:length(thr)
%         betar=gretna_hierarchy_weight(Rand{i,j},0);
%         brand(i,j)=betar.real;
%     end
% end
% bzscore=(b-mean(brand(~isnan(brand))))./std(brand(~isnan(brand)));
% ab=(sum(b)-sum(b([1 end]))/2)*deltas;
% abzscore=(sum(bzscore)-sum(bzscore([1 end]))/2)*deltas;
% save([output_b,'Hierarchy_',inputfile(1:end-4),'.mat'],'b','bzscore','ab','abzscore')
% toc(tb)
% fprintf('\n')
%% Degree
fprintf('Calculating Degree of %s>>>>',inputfile)
td=tic;
output_d=[outputpath,'Degree/'];
if ~isdir(output_d)
    mkdir(output_d)
end
for i=1:length(thr)
    [Dc(i),Dcnodal(:,i)]=gretna_node_degree_weight(A{i});
end
aDc=(sum(Dc)-sum(Dc([1 end]))/2)*deltas;
[m,n]=size(Dcnodal);
for i=1:m
    aDcnodal(1,i)=(sum(Dcnodal(i,:))-sum(Dcnodal(i,[1 end]))/2)*deltas;    
end

save([output_d,'Degree_',inputfile(1:end-4),'.mat'],'Dc','Dcnodal','aDc','aDcnodal')
toc(td)
fprintf('\n')
%% Betweenness
fprintf('Calculating Betweenness of %s>>>>',inputfile)
td=tic;
output_be=[outputpath,'Betweenness/'];
if ~isdir(output_be)
    mkdir(output_be)
end
for i=1:length(thr)
[bc(1,i),bcnodal(:,i)]=gretna_node_betweenness_weight(A{i});
end
abc=(sum(bc)-sum(bc([1 end]))/2)*deltas;
[m,n]=size(bcnodal);
for i=1:m
    abcnodal(1,i)=(sum(bcnodal(i,:))-sum(bcnodal(i,[1 end]))/2)*deltas;    
end
save([output_be,'Betweenness_',inputfile(1:end-4),'.mat'],'bc','bcnodal','abc','abcnodal')
toc(td)
fprintf('\n')
fprintf('\n')
toc
fprintf('\n')
fprintf('\n')