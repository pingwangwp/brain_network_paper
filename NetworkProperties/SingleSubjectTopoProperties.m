function SingleSubjectTopoProperties(inputpath,inputfile,outputpath)
tic

%% Modifying the path here !!!!!!!!!!!!!!
% ****************************************************************************************
addpath(genpath('GRETNA-2.0.0_release'))   
% ****************************************************************************************
%% 
if ~isdir(outputpath)
    mkdir(outputpath)
end

InputFile=[inputpath,'/',inputfile];
ftype=InputFile(end-2:end);
if ftype=='txt'
    A=load(InputFile);
elseif ftype=='mat'
    realNet=load(InputFile);
    A=realNet.A;
end
% RandNetFile=[inputRandNetpath,'RandNet_',inputfile];
% RandNet=load(RandNetFile);
% Rand=RandNet.Rand;
A(find(A<0))=0;    %positive network;
% A=abs(A);        %abs network

A=A-diag(diag(A));    %delete diag elements
A=A(1:90,1:90);
%% GEN RandNets
num_RandNet=1000;    
Rand=[];
fprintf('Generating %d RandNets>>>\n',num_RandNet);
trand=tic;
for i=1:num_RandNet
    if length(find(A==0))>length(A)
        Rand{i,1}=gretna_gen_random_network1_weight(A);     %if A is not full connected network, use rand_network1
    else
        Rand{i,1}=gretna_gen_random_network2_weight(A);      %if A is full connected network, use rand_network2
    end
end
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
output_cp=[outputpath,'ClusterCoef/'];
if ~isdir(output_cp)
    mkdir(output_cp)
end
output_lp=[outputpath,'ShortestPath/'];
if ~isdir(output_lp)
    mkdir(output_lp)
end
[Cp,Cp_nodal] = gretna_node_clustcoeff_weight(A,2);
[Lp,Lp_nodal] = gretna_node_shortestpathlength_weight(A);
for i=1:length(Rand)
    Cp_rand(i,1)=gretna_node_clustcoeff_weight(Rand{i,1},2);
    Lp_rand(i,1)=gretna_node_shortestpathlength_weight(Rand{i,1});
end
Gamma=Cp./mean(Cp_rand);
Lambda=Lp./mean(Lp_rand);
Sigma=Gamma./Lambda;
save([output_sm,'SmallWorld_',inputfile(1:end-4),'.mat'],'Cp','Lp','Gamma','Lambda','Sigma')
save([output_cp,'CpNodal_',inputfile(1:end-4),'.mat'],'Cp_nodal')
save([output_lp,'LpNodal_',inputfile(1:end-4),'.mat'],'Lp_nodal')
toc(tsm)
fprintf('\n')
%% NetworkEfficency (global and nodal)
fprintf('Calculating Network Efficency of %s>>>>',inputfile)
te=tic;
output_ne=[outputpath,'NetworkEfficency/'];
if ~isdir(output_ne)
    mkdir(output_ne)
end
[Eg, Egnodal]=gretna_node_global_efficiency_weight(A);
[Eloc Elocnodal]=gretna_node_local_efficiency_weight(A);
save([output_ne,'NetworkEfficency_',inputfile(1:end-4),'.mat'],'Eg','Eloc','Egnodal','Elocnodal')
toc(te)
fprintf('\n')
%% Assortativity
% fprintf('Calculating Assortativity of %s>>>>',inputfile)
% tr=tic;
% output_r=[outputpath,'Assortativity/'];
% if ~isdir(output_r)
%     mkdir(output_r)
% end
% r=gretna_assortativity_weight(A,0);
% r=r.real;
% for i=1:length(Rand)
%     rr=gretna_assortativity_weight(Rand{i,1},0);
%     rrand(i,1)=rr.real;
% end
% rzscore=(r- mean(rrand))/(std(rrand));
% save([output_r,'Assortativity_',inputfile(1:end-4),'.mat'],'r','rzscore')
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
% beta=gretna_hierarchy_weight(A,0);
% b=beta.real;
% for i=1:length(Rand)
%     betar=gretna_hierarchy_weight(Rand{i,1},0);
%     brand(i)=betar.real;
% end
% bzscore=(b-mean(brand(~isnan(brand))))/std(brand(~isnan(brand)));
% save([output_b,'Hierarchy_',inputfile(1:end-4),'.mat'],'b','bzscore')
% toc(tb)
% fprintf('\n')
%% Degree
fprintf('Calculating Degree of %s>>>>',inputfile)
td=tic;
output_d=[outputpath,'Degree/'];
if ~isdir(output_d)
    mkdir(output_d)
end
[Dc,Dcnodal]=gretna_node_degree_weight(A);
save([output_d,'Degree_',inputfile(1:end-4),'.mat'],'Dc','Dcnodal')
toc(td)
fprintf('\n')
%% Betweenness
fprintf('Calculating Betweenness of %s>>>>',inputfile)
td=tic;
output_be=[outputpath,'Betweenness/'];
if ~isdir(output_be)
    mkdir(output_be)
end
[bc,bcnodal]=gretna_node_betweenness_weight(A);
save([output_be,'Betweenness_',inputfile(1:end-4),'.mat'],'bc','bcnodal')
toc(td)
fprintf('\n')
fprintf('\n')
toc
fprintf('\n')
fprintf('\n')