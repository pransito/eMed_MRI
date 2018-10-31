% update the paths struct to indicate where the VR logfiles are
root_log = 'E:\NGFN-Plus Alcohol\fMRI_VR\VR_Logfiles';

% get Bonn VR logfiles' names in order
cd(root_log)
cd('Bonn')
bonn_logs = cellstr(ls('*VR*.log'));

% for ll = 1:length(bonn_logs)
%     cur_name  = bonn_logs{ll};
%     cur_split = strsplit(cur_name,'ADD_P');
%     if ~strcmp(cur_split{2}(1),'_')
%         % get a new name
%         new_name = ['ADD_P_' cur_split{2}];
%         
%         % create the new file
%         copyfile(cur_name,new_name)
%         
%         % delete the wrong file
%         delete(cur_name)
%         
%     else
%         % do nothing
%     end
% end

% get Bonn VR logfiles' names in order
cd(root_log)
cd('Bonn')
bonn_logs = cellstr(ls('*VR*.log'));
not_found = {};
not_used  = {}; % logfiles that haven't been picked

% cd to root
cd(root_log)
cd('Berlin')
not_used = [not_used;cellstr(ls('*.log'))];
cd(root_log)
cd('Mannheim')
not_used = [not_used;cellstr(ls('*.log'))];
cd(root_log)
cd('Bonn')
not_used = [not_used;cellstr(ls('*.log'))];

for pp = 1:length(paths)
    cur_path = paths(pp);
    
    % cd to root
    cd(root_log)
    
    % which site?
    cd(cur_path.site)
    
    % what is the the id to look for?
    if strcmp(cur_path.site,'Mannheim')
        hash = strsplit(cur_path.id,'_');
        hash = [hash{1} '1_' hash{2}];
    elseif  strcmp(cur_path.site,'Bonn')
        hash = cur_path.id(1:9);
    else
        hash = cur_path.id;
    end
    
    % now get the right logfile for VR
    cur_logfiles = cellstr(ls([hash '*']));
    assert(length(cur_logfiles) == 1);
    if isempty(cur_logfiles{1})
        warning(['No logfile found for ' hash])
        not_found = [not_found hash];
    else
        % strike off of the list of not used
        cur_ind           = find(~cellfun(@isempty,strfind(not_used,cur_logfiles{1})));
        not_used(cur_ind) = [];
    end
    
    % write in the path struct
    cur_path.VR_log = fullfile(pwd,cur_logfiles);
    
    paths(pp) = cur_path;
    
end

% saving the changed path struct
%save(path_struct,'paths')