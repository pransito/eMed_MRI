% make struct array to get full paths to
% t1
% alcue
% faces
% nback
% vr

%% prep struct array
paths              = [];
paths.id           = [];
paths.t1           = [];
paths.t1_config    = [];
paths.alcue        = [];
paths.alcue_config = [];
paths.alcue_log    = [];
paths.faces        = [];
paths.faces_config = [];
paths.nback        = [];
paths.nback_config = [];
paths.vr           = [];
paths.vr_config    = [];

paths_bln   = paths;
paths_mnm   = paths;
paths_bnn   = paths;

%% some root paths
% inventory
path_inv         = 'S:\AG\AG-Emotional-Neuroscience\Restricted\NGFN\eMed\Inventarlisten\ngfn_inventory.csv';

% data root
data_root = 'S:\AG\AG-Emotional-Neuroscience-Backup\NGFN';

% t1
root_t1_Berlin   = fullfile(data_root,'sMRI_Mprage\Mprage_Nifti\Berlin');
root_t1_Mannheim = fullfile(data_root,'sMRI_Mprage\Mprage_Nifti\Mannheim');
root_t1_Bonn     = fullfile(data_root,'sMRI_Mprage\Mprage_Nifti\Bonn');

% alcue
root_alcue_Berlin     = fullfile(data_root,'fMRI_ALCUE\ALCUE_Nifti\Berlin');
root_alcue_Mannheim   = fullfile(data_root,'fMRI_ALCUE\ALCUE_Nifti\Mannheim'); 
root_alcue_Bonn       = fullfile(data_root,'fMRI_ALCUE\ALCUE_Nifti\Bonn');

% alcue log
root_alcue_log_Berlin = fullfile(data_root,'fMRI_ALCUE\ALCUE_Logfiles\logfiles');

% faces
root_faces_Berlin   = fullfile(data_root,'fMRI_Faces\Faces_Nifti\Berlin');
root_faces_Mannheim = fullfile(data_root,'fMRI_Faces\Faces_Nifti\Mannheim'); 
root_faces_Bonn     = fullfile(data_root,'fMRI_Faces\Faces_Nifti\Bonn'); 

% nback
root_nback_Berlin   = fullfile(data_root,'fMRI_NBack\NBack_Nifti\Berlin');
root_nback_Mannheim = fullfile(data_root,'fMRI_NBack\NBack_Nifti\Mannheim');
root_nback_Bonn     = fullfile(data_root,'fMRI_NBack\NBack_Nifti\Bonn');

% % nback log
% root_nback_log_Berlin   = 'S:\AG\AG-Emotional-Neuroscience-Backup\NGFN\fMRI_NBack\NBack_Logfiles\Berlin';
% root_nback_log_Mannheim = 'S:\AG\AG-Emotional-Neuroscience-Backup\NGFN\fMRI_NBack\NBack_Logfiles\Mannheim';
% root_nback_log_Bonn     = 'S:\AG\AG-Emotional-Neuroscience-Backup\NGFN\fMRI_NBack\NBack_Logfiles\Bonn';

root_vr_Berlin   = fullfile(data_root,'fMRI_VR\VR_Nifti\Berlin');
root_vr_Mannheim = fullfile(data_root,'fMRI_VR\VR_Nifti\Mannheim');
root_vr_Bonn     = fullfile(data_root,'fMRI_VR\VR_Nifti\Bonn');

%% subs
% the inventory
inv      = readtable(path_inv,'delimiter','\t');

% all subs Berlin
inv_bln  = inv(~cellfun(@isempty,strfind(inv.site,'Berlin')),:);
subs_bln = inv_bln.Co_ID; 

% subs Mannheim
inv_mnm    = inv(~cellfun(@isempty,strfind(inv.site,'Mannheim')),:);
subs_mnm   = inv_mnm.ID_initials; 
subs_mnm_2 = inv_mnm.ID_initials_NGFN; 

% subs Bonn
inv_bnn  = inv(~cellfun(@isempty,strfind(inv.site,'Bonn')),:);
subs_bnn = inv_bnn.Co_ID; % unclear which one is the correct ID

%% t1 Berlin
cd(root_t1_Berlin)
all_files = cellstr(ls('*.nii'));

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    paths_bln(ii).id = cur_sub;
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no t1 found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        warning(['multiple matches for t1: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path         = fullfile(pwd,all_files{cur_ind});
    paths_bln(ii).t1 = cur_path; 
    
    % write path to config file
    cur_path         = fullfile(pwd,'mprage_config.txt');
    paths_bln(ii).t1_config = cur_path; 
end

%% t1 Mannheim
cd(root_t1_Mannheim)
all_files = cellstr(ls());

for ii = 1:length(subs_mnm)
    % cur sub
    cur_sub_full     = subs_mnm{ii};
    paths_mnm(ii).id = cur_sub_full;
    cur_sub          = strsplit(cur_sub_full,'_'); 
    cur_sub          = cur_sub{1};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % check in other id variable
    if length(cur_ind) == 0
        
        % other id variable
        cur_sub_full     = subs_mnm_2{ii};
        cur_sub          = strsplit(cur_sub_full,'_'); 
        cur_sub          = cur_sub{1};
        
        % find the current sub
        cur_ind = strfind(all_files,cur_sub);
        cur_ind = find(~cellfun(@isempty,cur_ind));
        
        % in case now something was found
        if length(cur_ind) == 1
            warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
            paths_mnm(ii).id = cur_sub_full;
        end
        
    end
        
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no t1 found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for t1; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path         = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs         = cellstr(ls());
    cd(cur_dirs{3});
    
    % nii
    cur_nii          = cellstr(ls('*nii'));
    if length(cur_nii) == 1
        paths_mnm(ii).t1 = fullfile(pwd,cur_nii{1});  
    else
        warning(['something went wrong when noting down nii: ' cur_sub])
    end
    
    % config txt
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).t1_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt: ' cur_sub])
    end
    
    % go home
    cd(root_t1_Mannheim)
end

%% t1 Bonn
cd(root_t1_Bonn)
all_files = cellstr(ls());

for ii = 1:length(subs_bnn)
    % cur sub
    cur_sub          = subs_bnn{ii};
    paths_bnn(ii).id = cur_sub_full;
       
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
         
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no t1 found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for t1; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path         = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs         = cellstr(ls());
    cd(cur_dirs{3});
    
    % nii
    cur_nii          = cellstr(ls('*nii'));
    if length(cur_nii) == 1
        paths_bnn(ii).t1 = fullfile(pwd,cur_nii{1});  
    else
        warning(['something went wrong when noting down nii: ' cur_sub])
    end
    
    % config txt
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_bnn(ii).t1_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt: ' cur_sub])
    end
    % go home
    cd(root_t1_Bonn)
end

%% ALCUE Berlin
cd(root_alcue_Berlin)
all_files = cellstr(ls());

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no alcue found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        warning(['multiple matches for alcue: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    paths_bln(ii).alcue = cur_path; 
    
    % write path to config file
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_bln(ii).alcue_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt alcue: ' cur_sub])
    end
    % go home
    cd(root_alcue_Berlin)
end

%% ALCUE logfiles Berlin
cd(root_alcue_log_Berlin)
all_files = cellstr(ls());

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no alcue log found: ' cur_sub])
        continue
    elseif length(cur_ind) == 2
        % this is the correct case
        cur_ind = cur_ind(1);
    elseif length(cur_ind) > 2
        warning(['multiple matches for alcue log: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path                = fullfile(pwd,all_files{cur_ind});
    paths_bln(ii).alcue_log = cur_path; 
    
    % go home
    cd(root_alcue_Berlin)
end

%% ALCUE Mannheim
cd(root_alcue_Mannheim)
all_files = cellstr(ls());

for ii = 1:length(subs_mnm)
    % cur sub
    cur_sub_full     = subs_mnm{ii};
    paths_mnm(ii).id = cur_sub_full;
    cur_sub          = strsplit(cur_sub_full,'_'); 
    cur_sub          = cur_sub{1};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % check in other id variable
    if length(cur_ind) == 0
        
        % other id variable
        cur_sub_full     = subs_mnm_2{ii};
        cur_sub          = strsplit(cur_sub_full,'_'); 
        cur_sub          = cur_sub{1};
        
        % find the current sub
        cur_ind = strfind(all_files,cur_sub);
        cur_ind = find(~cellfun(@isempty,cur_ind));
        
        % in case now something was found
        if length(cur_ind) == 1
            warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
            paths_mnm(ii).id = cur_sub_full;
        end
        
    end
        
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no alcue found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for t1; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs            = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_dirs{3});
    paths_mnm(ii).alcue = cur_path;  
    
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).alcue_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down alcue config txt: ' cur_sub])
    end
    
    % go home
    cd(root_alcue_Mannheim)
end

%% ALCUE Bonn
cd(root_alcue_Bonn)
all_files = cellstr(ls());

for ii = 1:length(subs_bnn)
    % cur sub
    cur_sub          = subs_bnn{ii};
       
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
         
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no t1 found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for t1; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs            = cellstr(ls());
    cur_path            = fullfile(pwd,cur_dirs{3});
    paths_bnn(ii).alcue = cur_path;  
       
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).alcue_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt: ' cur_sub])
    end
    % go home
    cd(root_alcue_Bonn)
end

%% FACES Berlin
cd(root_faces_Berlin)
all_files = cellstr(ls());

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no faces folder found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        warning(['multiple matches for faces: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_paths           = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_paths{3});
    paths_bln(ii).faces = cur_path; 
    
    % write path to config file
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_bln(ii).faces_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt faces: ' cur_sub])
    end
    % go home
    cd(root_faces_Berlin)
end

%% FACES Mannheim
cd(root_faces_Mannheim)
all_files = cellstr(ls());

for ii = 1:length(subs_mnm)
    % cur sub
    cur_sub_full     = subs_mnm{ii};
    cur_sub          = strsplit(cur_sub_full,'_'); 
    cur_sub          = cur_sub{1};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % check in other id variable
    if length(cur_ind) == 0
        
        % other id variable
        cur_sub_full     = subs_mnm_2{ii};
        cur_sub          = strsplit(cur_sub_full,'_'); 
        cur_sub          = cur_sub{1};
        
        % find the current sub
        cur_ind = strfind(all_files,cur_sub);
        cur_ind = find(~cellfun(@isempty,cur_ind));
        
        % in case now something was found
        if length(cur_ind) == 1
            warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
            paths_mnm(ii).id = cur_sub_full;
        end
        
    end
        
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no faces found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for faces; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs            = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_dirs{3});
    paths_mnm(ii).faces = cur_path;  
    
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).faces_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down alcue config txt: ' cur_sub])
    end
    
    % go home
    cd(root_faces_Mannheim)
end

%% FACES Bonn
cd(root_faces_Bonn)
all_files = cellstr(ls());

for ii = 1:length(subs_bnn)
    % cur sub
    cur_sub          = subs_bnn{ii};
       
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
         
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no t1 found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for faces; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    % check if already nii in here
    cur_nii = cellstr(ls('*nii'));
    if ~strcmp(cur_nii{1},'')
        cur_path = pwd;
    else
        cur_dirs            = cellstr(ls());
        cur_path            = fullfile(pwd,cur_dirs{3});
    end
    paths_bnn(ii).faces = cur_path;
       
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).faces_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down faces config txt: ' cur_sub])
    end
    % go home
    cd(root_faces_Bonn)
end

%% NBACK Berlin
cd(root_nback_Berlin)
all_files = cellstr(ls());

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no nback folder found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        warning(['multiple matches for nback: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_paths           = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_paths{3});
    paths_bln(ii).nback = cur_path; 
    
    % write path to config file
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_bln(ii).nback_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down nback config txt nback: ' cur_sub])
    end
    % go home
    cd(root_nback_Berlin)
end

%% NBACK Mannheim
cd(root_nback_Mannheim)
all_files = cellstr(ls());

for ii = 1:length(subs_mnm)
    % cur sub
    cur_sub_full     = subs_mnm{ii};
    cur_sub          = strsplit(cur_sub_full,'_'); 
    cur_sub          = cur_sub{1};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % check in other id variable
    if length(cur_ind) == 0
        
        % other id variable
        cur_sub_full     = subs_mnm_2{ii};
        cur_sub          = strsplit(cur_sub_full,'_'); 
        cur_sub          = cur_sub{1};
        
        % find the current sub
        cur_ind = strfind(all_files,cur_sub);
        cur_ind = find(~cellfun(@isempty,cur_ind));
        
        % in case now something was found
        if length(cur_ind) == 1
            warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
            paths_mnm(ii).id = cur_sub_full;
        end
        
    end
        
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no nback found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for nback; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs            = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_dirs{3});
    paths_mnm(ii).nback = cur_path;  
    
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).nback_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down alcue config txt: ' cur_sub])
    end
    
    % go home
    cd(root_nback_Mannheim)
end

%% NBACK Bonn
cd(root_nback_Bonn)
all_files = cellstr(ls());

for ii = 1:length(subs_bnn)
    % cur sub
    cur_sub          = subs_bnn{ii};
       
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
         
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no nack found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for nback; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    % check if already nii in here
    cur_nii = cellstr(ls('*nii'));
    if ~strcmp(cur_nii{1},'')
        cur_path = pwd;
    else
        cur_dirs            = cellstr(ls());
        cur_path            = fullfile(pwd,cur_dirs{3});
    end
    paths_bnn(ii).nback = cur_path;
       
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).nback_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down nback config txt: ' cur_sub])
    end
    % go home
    cd(root_nback_Bonn)
end

%% VR Berlin
cd(root_vr_Berlin)
all_files = cellstr(ls());

for ii = 1:length(subs_bln)
    % cur sub
    cur_sub          = subs_bln{ii};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % checking if ok
    if length(cur_ind) == 0 
        warning(['no vr folder found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        warning(['multiple matches for vr: ' cur_sub])
        continue
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_paths           = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_paths{3});
    paths_bln(ii).vr = cur_path; 
    
    % write path to config file
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_bln(ii).vr_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down config txt vr: ' cur_sub])
    end
    % go home
    cd(root_vr_Berlin)
end

%% VR Mannheim
cd(root_vr_Mannheim)
all_files = cellstr(ls());

for ii = 1:length(subs_mnm)
    % cur sub
    cur_sub_full     = subs_mnm{ii};
    cur_sub          = strsplit(cur_sub_full,'_'); 
    cur_sub          = cur_sub{1};
    
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
    
    % check in other id variable
    if length(cur_ind) == 0
        
        % other id variable
        cur_sub_full     = subs_mnm_2{ii};
        cur_sub          = strsplit(cur_sub_full,'_'); 
        cur_sub          = cur_sub{1};
        
        % find the current sub
        cur_ind = strfind(all_files,cur_sub);
        cur_ind = find(~cellfun(@isempty,cur_ind));
        
        % in case now something was found
        if length(cur_ind) == 1
            warning(['using ID_initials instead of ID_initials_ngfn: ' cur_sub])
            paths_mnm(ii).id = cur_sub_full;
        end
        
    end
        
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no vr found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for nback; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    cur_dirs            = cellstr(ls());
    cur_path            = fullfile(cur_path,cur_dirs{3});
    paths_mnm(ii).vr = cur_path;  
    
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).vr_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down vr config txt: ' cur_sub])
    end
    
    % go home
    cd(root_vr_Mannheim)
end

%% VR Bonn
cd(root_vr_Bonn)
all_files = cellstr(ls());

for ii = 1:length(subs_bnn)
    % cur sub
    cur_sub          = subs_bnn{ii};
       
    % find the current sub
    cur_ind = strfind(all_files,cur_sub);
    cur_ind = find(~cellfun(@isempty,cur_ind));
         
    % checking if ok   
    if length(cur_ind) == 0
        warning(['no vr found: ' cur_sub])
        continue
    elseif length(cur_ind) > 1
        cur_ind    = cur_ind(1);
        warning(['multiple matches for vr; taking first one: ' cur_sub])
    end
    
    % write in struct
    cur_path            = fullfile(pwd,all_files{cur_ind});
    cd(cur_path)
    % check if already nii in here
    cur_nii = cellstr(ls('*nii'));
    if ~strcmp(cur_nii{1},'')
        cur_path = pwd;
    else
        cur_dirs            = cellstr(ls());
        cur_path            = fullfile(pwd,cur_dirs{3});
    end
    paths_bnn(ii).vr = cur_path;
       
    % config txt
    cd(cur_path)
    cur_txt          = cellstr(ls('*txt'));
    if length(cur_txt) == 1
        paths_mnm(ii).vr_config = fullfile(pwd,cur_txt{1});  
    else
        warning(['something went wrong when noting down vr config txt: ' cur_sub])
    end
    % go home
    cd(root_vr_Bonn)
end

paths = [paths_bln,paths_bnn,paths_mnm];







