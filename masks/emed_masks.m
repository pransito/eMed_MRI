% this script generates ROI masks (.nii files)
% according to list of desired regions
% then it cuts some regions to avoid region overlap
% author: Alexander Genauck
% date: March 2017

%% PREPARATIONS

% path where to save (type in path as a string or leave as is)
dest_folder = pwd;
cur_atlas   = 'C:\Program Files\spm12\tpm\labels_Neuromorphometrics.xml';

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
    'Accumbens', ...
    'Putamen', ...                % B.G. action selection/ value represent.
    'Thalamus', ...
    'Caudate', ...                % B.G. action selection
    'anterior cingulate',...      % repr. of value for action outcome pred
    'Amygdala', ...               % amygdala represents pavlovian value
    'orbital gyrus', ...          % value representation ANDREA model
    'thalamus',...                % B.G. action selection
    'MSFG', ...                   % medial segment of frontal gyrus
    'insula' ...                  % e.g. lesion of insula in smoking leads
                                  % to cessation of addiction
    };

%% GENERATING THE MASKS
% delete existing masks folder
try
    rmdir('masks','s')
catch
    disp('No masks folder there yet.')
end

mkdir(dest_folder);
cd(dest_folder);
mkdir('masks');
cd('masks');
base_dir = pwd;

% select an atlas
xA=spm_atlas('load',cur_atlas);

% use anat_region_list to pick the regions from the Atlas
all_regions = [];
for ii = 1:length(anat_region_list)
    for jj = 1:length(xA.labels)
        cur_find = strfind(xA.labels(jj).name,anat_region_list{ii});
        if isempty(cur_find)
            cur_find = strfind(xA.labels(jj).name, ...
                lower(anat_region_list{ii}));
        end
        if ~isempty(cur_find)
            all_regions = [all_regions; cellstr(xA.labels(jj).name)];
        end        
    end
end
S = all_regions';

% GUI-select
% S=spm_atlas('select',xA);

for i = 1:size(S,2)
    disp(['I am at region number... ', ...
        num2str(i), 'of ', num2str(size(S,2))])
    fname=strcat(S{i},'.nii');
    VM=spm_atlas('mask',xA,S{i});
    VM.fname=fname;
    disp(['I found and write region... ', fname])
    spm_write_vol(VM,spm_read_vols(VM));
end

%% CUTTING REGIONS
% striatum minus accumbens
striatum   = {'*Putamen*','*Caudate*'};
min_region = cellstr(ls('*Accumbens*'));

for ii = 1:length(striatum)
    cur_regions   = cellstr(ls(striatum{ii}));
    cur_im_struct = [cur_regions;min_region];
    tmp      = strsplit(cur_regions{1},'.nii');
    % left
    tmp      = strsplit(cur_regions{1},'.nii');
    out_name = [tmp{1} ' minus Accumbens.nii'];
    f        = '(i1 - (i3+i4))>0';
    spm_imcalc(cur_im_struct,out_name,f,{0})
    % right
    tmp      = strsplit(cur_regions{2},'.nii');
    out_name = [tmp{1} ' minus Accumbens.nii'];
    f        = '(i2 - (i3+i4))>0';
    spm_imcalc(cur_im_struct,out_name,f,{0})
    % moving unused regions
    mkdir('out')
    movefile(cur_regions{1},['out' filesep cur_regions{1}]);
    movefile(cur_regions{2},['out' filesep cur_regions{2}],'f');
end

% ofc (minus mpfc; alles orbitale (anterior, lateral, medial, inferior))
OFC        = cellstr(ls('*orbital*'));
min_region = cellstr(ls('*MSFG*'));

for ii = 1:length(OFC)
    cur_regions    = OFC(ii);
    cur_im_struct = [cur_regions;min_region];
    tmp      = strsplit(cur_regions{1},'.nii');
    % left
    tmp      = strsplit(cur_regions{1},'.nii');
    out_name = [tmp{1} ' minus MSFG.nii'];
    f        = '(i1 - (i2+i3))>0';
    spm_imcalc(cur_im_struct,out_name,f,{0})
    % moving unused regions
    mkdir('out')
    movefile(cur_regions{1},['out' filesep cur_regions{1}]);
end

% write all images again in 0-1 format
all_regions = cellstr(ls('*.nii'));
for ii = 1:length(all_regions)
    cur_region = all_regions(ii);
    out_name   = all_regions{ii};
    f        = 'i1>0';
    spm_imcalc(cur_region,out_name,f,{0})
end

% write in ouput file what was used
S = cellstr(ls('*.nii'));
writetable(cell2table(S,'VariableNames',{'MASKS_USED'}),'masks_used.txt')

% check whether there are really no overlaps
all_regions = cellstr(ls('*.nii'));
out_name    = 'all_in_one.nii';
f           = 'sum(X)';
spm_imcalc(all_regions,out_name,f,{1})
tmp = spm_read_vols(spm_vol('all_in_one.nii'));

if (sum(sum(sum(tmp > 0.99))) > 0) && (sum(sum(sum(tmp > 1))) == 0)
    disp('There are no overlaps between regions!')
else
    disp('Careful!!! There are overlaps between regions!')
end

cd ..
