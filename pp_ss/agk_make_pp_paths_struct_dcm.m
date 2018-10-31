function paths = agk_make_pp_paths_struct_dcm()
% make struct array to get full paths to dicoms
% and to logfiles for
% t1
% alcue
% faces
% nback
% vr

%% prep struct array
paths              = [];
paths.id           = [];
paths.site         = [];
paths.t1           = [];
paths.ALCUE        = [];
paths.ALCUE_log    = [];
paths.Faces        = [];
paths.Faces_log    = [];
paths.NBack        = [];
paths.NBack_log    = [];
paths.VR           = [];
paths.VR_log       = [];

paths_cell  = {paths;paths;paths}; % one per site

%% some root paths
% save struct path
save_struct_path = 'C:\Users\genaucka\Google Drive\Library\MATLAB\eMed\pp_ss';

% inventory
path_inv         = 'C:\Users\genaucka\Google Drive\Library\MATLAB\eMed\pp_ss\ngfn_inventory.csv';
path_spss_bnn    = 'C:\Users\genaucka\Google Drive\Library\MATLAB\eMed\pp_ss\spss_bnn.csv';

% data root
data_root = 'E:\NGFN-Plus Alcohol';

% t1?
do_t1 = 1;

%tasks = {'VR'};
tasks = {'ALCUE','Faces','NBack','VR'};
sites = {'Berlin','Mannheim','Bonn'};
%sites = {'Bonn'};

cur_dir_mpr_dcm = fullfile(data_root,'MRI_Mprage', sites{1});


%% subs
% the inventory
inv        = readtable(path_inv,'delimiter','\t');

% all subs Berlin
inv_bln    = inv(~cellfun(@isempty,strfind(inv.site,'Berlin')),:);
subs_bln   = inv_bln.Co_ID;
subs_bln_2 = repmat('999999',length(subs_bln),1);

% subs Mannheim
inv_mnm    = inv(~cellfun(@isempty,strfind(inv.site,'Mannheim')),:);
subs_mnm   = inv_mnm.ID_initials;
subs_mnm_2 = inv_mnm.ID_initials_NGFN;

% subs Bonn
inv_bnn    = inv(~cellfun(@isempty,strfind(inv.site,'Bonn')),:);
subs_bnn   = inv_bnn.ID_initials_NGFN; % pretty sure this is the right ID
subs_bnn_2 = repmat('999999',length(subs_bln),1);

% the Bonn ID needs some editing
for ss = 1:length(subs_bnn)
    cur_sub    = subs_bnn{ss};
    cur_spl    = strsplit(cur_sub,'_');
    first_part = sprintf('%03s',cur_spl{1});
    
    if length(cur_spl) == 2
        cur_sub = ['ADD_P_' first_part '_' cur_spl{2}];
    else
        cur_sub = ['ADD_P_' first_part];
    end
    subs_bnn{ss} = cur_sub;
end

all_subs   = {subs_bln;subs_mnm;subs_bnn};
all_subs_2 = {subs_bln_2;subs_mnm_2;subs_bnn_2};

%% t1
if do_t1
    for ss = 1:length(sites)
        % dicoms t1 current site directory
        cur_dir_mpr_dcm = fullfile(data_root,'MRI_Mprage', sites{ss});
        cd(cur_dir_mpr_dcm)
        
        % the dicom directories we have there
        all_files        = cellstr(ls());
        if strcmp(sites{ss},'Bonn')
            all_files        = cellstr(ls('t1*'));
            all_files_edited = upper(strrep(all_files,'_',''));
        end
        
        for ii = 1:length(all_subs{ss})
            cd(cur_dir_mpr_dcm)
            
            % write down site
            paths_cell{ss}(ii).site = sites{ss};
            
            % cur sub
            cur_sub_full          = all_subs{ss}{ii};
            paths_cell{ss}(ii).id = cur_sub_full;
            
            % edit cur_sub
            if strcmp(sites{ss},'Mannheim')
                cur_sub          = strsplit(cur_sub_full,'_');
                cur_sub          = cur_sub{1};
            elseif strcmp(sites{ss},'Bonn')
                % edit down
                cur_sub = strsplit(cur_sub_full,'_');
                cur_sub = [cur_sub{1} '_' cur_sub{2} '_' cur_sub{3}];
            else
                cur_sub = cur_sub_full;
            end
            
            % find the current sub
            if strcmp(sites{ss},'Bonn')
                cur_ind = strfind(all_files_edited,strrep(cur_sub,'_',''));
            else
                cur_ind = strfind(all_files,cur_sub);
            end
            cur_ind = find(~cellfun(@isempty,cur_ind));
            
            % check in other id variable
            if isempty(cur_ind) && strcmp(sites{ss},'Mannheim')
                % other id variable
                cur_sub_full     = all_subs_2{ss}{ii};
                cur_sub          = strsplit(cur_sub_full,'_');
                cur_sub          = cur_sub{1};
                
                % find the current sub
                cur_ind = strfind(all_files,cur_sub);
                cur_ind = find(~cellfun(@isempty,cur_ind));
                
                % in case now something was found
                if length(cur_ind) == 1
                    warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
                    paths_cell{ss}(ii).id = cur_sub_full;
                end
            end
            
            % checking if ok
            if isempty(cur_ind)
                warning(['no t1 found: ' cur_sub])
                continue
            elseif length(cur_ind) > 1
                cur_ind    = cur_ind(1);
                warning(['multiple matches for t1; taking first one: ' cur_sub])
            end
            
            disp(['Found t1 dcm ', sites{ss} ' ' cur_sub])
            
            % get the path
            cur_path         = fullfile(pwd,all_files{cur_ind});
            cd(cur_path)
            
            % dcm check function
            cur_dcm = agk_check_dcm(cur_path,sites,ss,cur_sub,tasks,1);
            
            % write in struct
            if length(cur_dcm) > 100
                paths_cell{ss}(ii).t1 = cur_dcm;
            else
                warning(['something went wrong when noting down dcm: ' sites{ss} ' ' cur_sub])
            end
            
        end
    end
end


%% TASKS AND LOGFILES
for tt = 1:length(tasks)
    for ss = 1:length(sites)
        
        for kk = 1:2 % kind: task dicoms (1) or logfiles (2)?
            
            % dicoms and logfiles dir for task
            if kk == 1
                cur_dir_dicom = fullfile(data_root,['fMRI_' tasks{tt}],[tasks{tt} '_DICOM'],sites{ss});
            else
                cur_dir_dicom = fullfile(data_root,['fMRI_' tasks{tt}],[tasks{tt} '_Logfiles'],sites{ss});
            end
            
            cd(cur_dir_dicom)
            
            % the dicom directories we have there
            all_files        = cellstr(ls());
            if strcmp(sites{ss},'Bonn')
                all_files_edited = upper(strrep(all_files,'_',''));
            end
            
            for ii = 1:length(all_subs{ss})
                cd(cur_dir_dicom)
                
                % write down site
                paths_cell{ss}(ii).site = sites{ss};
                
                % cur sub
                cur_sub_full          = all_subs{ss}{ii};
                paths_cell{ss}(ii).id = cur_sub_full;
                
                % edit cur_sub
                if strcmp(sites{ss},'Mannheim')
                    cur_sub          = strsplit(cur_sub_full,'_');
                    cur_sub          = cur_sub{1};
                elseif strcmp(sites{ss},'Bonn')
                    % edit down
                    cur_sub = strsplit(cur_sub_full,'_');
                    cur_sub = [cur_sub{1} '_' cur_sub{2} '_' cur_sub{3}];
                else
                    cur_sub = cur_sub_full;
                end
                
                % find the current sub
                if strcmp(sites{ss},'Bonn')
                    cur_ind = strfind(all_files_edited,strrep(cur_sub,'_',''));
                else
                    cur_ind = strfind(all_files,cur_sub);
                end
                cur_ind = find(~cellfun(@isempty,cur_ind));
                
                % check in other id variable
                if isempty(cur_ind) && strcmp(sites{ss},'Mannheim')
                    % other id variable
                    cur_sub_full     = all_subs_2{ss}{ii};
                    cur_sub          = strsplit(cur_sub_full,'_');
                    cur_sub          = cur_sub{1};
                    
                    % find the current sub
                    cur_ind = strfind(all_files,cur_sub);
                    cur_ind = find(~cellfun(@isempty,cur_ind));
                    
                    % in case now something was found
                    if length(cur_ind) == 1
                        warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
                        paths_cell{ss}(ii).id = cur_sub_full;
                    end
                end
                
                % checking if ok
                if isempty(cur_ind)
                    if kk == 1
                        warning(['no task dcm found: ' cur_sub ' ' sites{ss} ' ' tasks{tt}])
                    else
                        warning(['no task logfile found: ' cur_sub ' ' sites{ss} ' ' tasks{tt}])
                    end
                    continue
                elseif length(cur_ind) > 1 && kk == 1
                    cur_ind    = cur_ind(1);
                    warning(['multiple matches for task dcm; taking first one: ' cur_sub ' ' sites{ss} ' ' tasks{tt}])
                end
                
                if kk == 1
                    disp(['Found task dcm ', cur_sub ' ' sites{ss} ' ' tasks{tt}])
                else
                    disp(['Found task logfile(s) ', cur_sub ' ' sites{ss} ' ' tasks{tt}])
                end
                
                % get the path
                if kk == 1
                    cur_path         = fullfile(pwd,all_files{cur_ind});
                    cd(cur_path)
                else
                    cur_dcm = fullfile(pwd,all_files(cur_ind));
                end
                
                % dcm check function
                if kk == 1
                    cur_dcm = agk_check_dcm(cur_path,sites,ss,cur_sub,tasks,tt);
                end
                
                % write in struct
                if kk == 1
                    des_field = tasks{tt};
                else
                    des_field = [tasks{tt} '_log'];
                end
                if (length(cur_dcm) > 100 && kk == 1) || kk == 2
                    paths_cell{ss}(ii) = setfield(paths_cell{ss}(ii),des_field,cur_dcm);
                else
                    warning(['something went wrong when noting down dcm: ' sites{ss} ' ' cur_sub ' ' tasks{tt}])
                end
                
            end
        end
    end
    
end

%% PACKING
paths = [paths_cell{1},paths_cell{2},paths_cell{3}];

% saving
warning('SAVING NOW!')
cd(save_struct_path)
save('ngfn_struct_paths_mri_dcm_NEW.mat','paths')
warning('SAVING COMPLETED!')
end

%% AUXILIARY FUNCTIONS
function cur_dcm = agk_check_dcm(cur_path,sites,ss,cur_sub,tasks,tt)
% function to check if there are dicoms
% will go recursively into directory if there is just an directory
% instead of image files in cur_path

cd(cur_path)
cur_dcm          = cellstr(ls('*dcm'));
if isempty(cur_dcm{1})
    cur_dcm = cellstr(ls('*IMA'));
end

if isempty(cur_dcm{1})
    % search for anything
    cur_dcm = cellstr(ls());
    
    if length(cur_dcm) == 2
        % empty dcm folder
        warning(disp(['empty dcm folder: ' sites{ss} ' ' cur_sub ' ' tasks{tt}]))
        cur_dcm = [];
        return
    end
    
    % something else is in there
    cur_dcm = cur_dcm(3:end);
    if length(cur_dcm) > 100
        % many other files
        disp(['...but no expected dcm or IMA files. But noted down other files: ' sites{ss} ' ' cur_sub ' ' tasks{tt}])
        cur_dcm = fullfile(cur_path,cur_dcm);
        return
    elseif isdir(fullfile(pwd,cur_dcm{1}))
        cd(fullfile(pwd,cur_dcm{1}))
        cur_path = pwd;
        cur_dcm = agk_check_dcm(cur_path,sites,ss,cur_sub,tasks,tt);
        return
    end
else
    cur_dcm = fullfile(cur_path,cur_dcm);
    return
end
end







