% this script generates ROI masks (.nii files)
% according to list of desired regions
% then it cuts some regions to avoid region overlap (?)
% after review addiction biology: 
% anterior insula from SPM12
% no more OFC merging
% new betas for effect sizes map
% author: Alexander Genauck
% date: Feb 2018

%% PREPARATIONS

% path where to save (type in path as a string or leave as is)
dest_folder = fullfile(pwd,'masks_AAL_paper');
mkdir(dest_folder)
cur_atlas   = 'C:\Program Files\spm12\tpm\AAL.xml';

% list of desired regions
% msfg (für mpfc) (-acc)
% acc
% accumbens
% putamen minus accumbens
% caudate minus accumbens
% thalamus proper
% amy
% insula
% ofc (minus mpfc; alles orbitale (anterior, lateral, medial, inferior))
anat_region_list = {...
    'Frontal_Sup_Medial', ...
    'Frontal_Sup_Orb', ...                
    'Frontal_Mid_Orb', ...
    'Frontal_Inf_Orb', ...
    'Frontal_Med_Orb', ...
    'Frontal_Sup_Orb_L.nii',...
    'Amygdala', ...      
    'Caudate', ...
    'Cingulum_Ant',...                  
    'Putamen', ...          
    'Thalamus'...                 
    };

%% GENERATING THE MASKS
% delete existing masks folder
try
    rmdir('masks_AAL_paper','s')
catch
    disp('No masks_AAL_paper folder there yet.')
end

mkdir(dest_folder);
cd(dest_folder);

generate_masks_from_atlas(cur_atlas,anat_region_list,pwd,'AAL_paper.nii',0)

% ADD Ant./Post. insula
cur_atlas   = 'C:\Program Files\spm12\tpm\labels_Neuromorphometrics.xml';
anat_region_list = {...
    'anterior insula', ...   
    'posterior insula', ...
    };
cd ..
generate_masks_from_atlas(cur_atlas,anat_region_list,pwd,'AAL_paper.nii',0)

%% MERGING LEFT AND RIGHT
% prep save L,R because we need it for later
mkdir('LR')

cur_regions = {'Amygdala', ...
    'Caudate', ...
    'Cingulum_Ant',...
    'AIns', ...
    'PIns', ...
    'Putamen', ...
    'Thalamus', ...
    'Med_Orb',...
    'Mid_Orb',...
    'Sup_Orb',...
    'Inf_Orb',...
    'Frontal_Sup_Medial' ...
    };

for ii = 1:length(cur_regions)
    cur_region = cur_regions{ii};
    LR = cellstr(ls(['*' cur_region '*']));
    
    % copy
    for jj = 1:length(LR)
        copyfile(LR{jj},[fullfile('LR',LR{jj})],'f');
    end
    
    % merge
    out_name = [cur_region '.nii'];
    cur_rand = num2str(rand);
    f        = ['sum(X)*' cur_rand];
    spm_imcalc(fullfile('LR',LR),fullfile('LR',out_name),f,{1});
    
    % delete L and R
    for jj = 1:length(LR)
        delete(fullfile('LR',LR{jj}));
    end
    
end

%% MERGING REGIONS
% % OFC
% OFC_L = cellstr(ls('*_ORB_L.nii'));
% OFC_R = cellstr(ls('*_ORB_R.nii'));
% 
% out_name = 'OFC_L.nii';
% f        = 'sum(X)';
% spm_imcalc(OFC_L,out_name,f,{1});
% out_name = 'OFC_R.nii';
% spm_imcalc(OFC_R,out_name,f,{1});
% 
% for ii = 1:length(OFC_L)
%     delete(OFC_L{ii});
% end
% 
% for ii = 1:length(OFC_R)
%     delete(OFC_R{ii});
% end

%% make a whole brain mask with effect sizes
% our masks
our_masks = cellstr(ls('*.nii'));
cd ..
cd ..
all_betas = readtable('all_betas.csv','Delimiter',';');
cd('masks_AAL_paper\tmp')

% folders
cur_home_tmp = pwd;
mkdir('combined_effect_sizes')
mkdir('female_effect_sizes')
mkdir('male_effect_sizes')

es_folders = {'combined_effect_sizes','female_effect_sizes', ...
    'male_effect_sizes'};

% images
all_ROIs = cellstr(ls('*.nii'));
x = all_ROIs;
x = strrep(x,'.nii','');
y = x;
y{~cellfun(@isempty,strfind(y,'Cingulum_Ant_L'))} = 'ACC_L';
y{~cellfun(@isempty,strfind(y,'Cingulum_Ant_R'))} = 'ACC_R';
y{~cellfun(@isempty,strfind(y,'Left AIns anterior insula'))} = 'Insula_Ant_L';
y{~cellfun(@isempty,strfind(y,'Right AIns anterior insula'))} = 'Insula_Ant_R';
y{~cellfun(@isempty,strfind(y,'Left PIns posterior insula'))} = 'Insula_Post_L';
y{~cellfun(@isempty,strfind(y,'Right PIns posterior insula'))} = 'Insula_Post_R';
y{~cellfun(@isempty,strfind(y,'Frontal_Sup_Medial_L'))} = 'MPFC_L';
y{~cellfun(@isempty,strfind(y,'Frontal_Sup_Medial_R'))} = 'MPFC_R';
y{~cellfun(@isempty,strfind(y,'Frontal_Inf_Orb_L'))} = 'OFC_Inf_L';
y{~cellfun(@isempty,strfind(y,'Frontal_Inf_Orb_R'))} = 'OFC_Inf_R';
y{~cellfun(@isempty,strfind(y,'Frontal_Med_Orb_L'))} = 'OFC_Med_L';
y{~cellfun(@isempty,strfind(y,'Frontal_Med_Orb_R'))} = 'OFC_Med_R';
y{~cellfun(@isempty,strfind(y,'Frontal_Mid_Orb_L'))} = 'OFC_Mid_L';
y{~cellfun(@isempty,strfind(y,'Frontal_Mid_Orb_R'))} = 'OFC_Mid_R';
y{~cellfun(@isempty,strfind(y,'Frontal_Sup_Orb_L'))} = 'OFC_Sup_L';
y{~cellfun(@isempty,strfind(y,'Frontal_Sup_Orb_R'))} = 'OFC_Sup_L';

query_vec = agk_recode_str(x,x,y);

% effect sizes
for qq = 1:length(query_vec)
    cur_ind = find(~cellfun(@isempty,strfind(all_betas.region,query_vec{qq})));
    es_combined(qq) = all_betas.beta_all(cur_ind);
    es_female(qq)   = all_betas.beta_fem(cur_ind);
    es_male(qq)     = all_betas.beta_male(cur_ind);
end

es_vecs = {es_combined*(-1),es_female*(-1),es_male*(-1)};

% apply it
for kk = 1:length(es_folders)
    % combined
    for ii = 1:length(all_ROIs)
        
        if es_vecs{kk}(ii)
            % prep
            out_name = fullfile(es_folders{kk},all_ROIs{ii});
            % copy
            copyfile(all_ROIs{ii},out_name,'f');
            
            % write effect size
            f        = ['i1*(' num2str(es_vecs{kk}(ii)) ')'];
            spm_imcalc(all_ROIs(ii),out_name,f,{0});
        end
       
    end
    
    % merging
    cd(es_folders{kk})
    cur_ROIs = cellstr(ls('*.nii'));
    out_name = [es_folders{kk} '.nii'];
    f        = 'sum(X)';
    spm_imcalc(cur_ROIs,out_name,f,{1});
    
    for ii = 1:length(all_ROIs)
        
        % delete unneeded .nii
        delete(all_ROIs{ii});
    end
    
    % go home
    cd(cur_home_tmp)
    
end

% % delete unneeded .nii
% all_ROIs = cellstr(ls('*.nii'));
% for ii = 1:length(all_ROIs)
%     delete(all_ROIs{ii});
% end





%% SLICE used
% 17:3:79
% new: 23:3:68 (4 rows)
% range mricron: 0.001 : 0.4
