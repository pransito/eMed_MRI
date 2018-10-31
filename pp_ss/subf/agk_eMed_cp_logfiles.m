function error_msg = agk_eMed_cp_logfiles(cur_struct,base_dir_pl,des_tasks,tasks,des_sites,sites)
% function that copies the logfiles
%try
cd(base_dir_pl)
cur_subf = fullfile(pwd,cur_struct.id);

% desired task logs
tasks = strcat(tasks,'_log');

% test here if it is the right site
C     = cellstr(cur_struct.site);
TEST  = sites(des_sites);
out   = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
if ~any(~cellfun(@isempty,out));
    error_msg = ['The subject ' cur_struct.id ' from ' cur_struct.site '... is not from desired site! I will skip.'];
    disp(error_msg)
    return
end

% prep the preprocessing for the desired tasks
all_fields = fieldnames(cur_struct);
for ff = 1:length(all_fields)
    % fields that are not for preprocessing
    C         = cellstr(all_fields(ff));
    TEST      = {'id','site','t1'};
    out       = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_out = ~any(~cellfun(@isempty,out));
    
    % test if from a desired task
    C        = cellstr(all_fields(ff));
    TEST     = tasks(des_tasks);
    out      = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_in = any(~cellfun(@isempty,out));
    
    if do_it_in && do_it_out
        
        % get logfiles
        cur_logs = getfield(cur_struct,all_fields{ff});
        if ~isempty(cur_logs)
           cur_tar = fullfile(base_dir_pl,cur_struct.id,strrep(all_fields{ff},'_log',''),'logfiles');
        else
            error_msg = ['The subject ' cur_struct.id ' task ' all_fields{ff} '... has no logfiles! I will skip.'];
            warning(error_msg);
            continue
        end
        
        % copy logfiles
        for cc = 1:length(cur_logs)
            copyfile(cur_logs{cc},cur_tar)
        end
        
        % report
        error_msg = ['For subject ' cur_struct.id ' task ' all_fields{ff} ' logfiles successfully copied!'];
        disp(error_msg)
        
    end
    
end

end