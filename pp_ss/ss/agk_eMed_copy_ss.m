function error_msg = agk_eMed_copy_ss(cur_struct,base_dir_pl,des_tasks,tasks,des_sites,sites)
% function that copies ss
cd(base_dir_pl)
cur_subf = fullfile(pwd,cur_struct.id);

% test here if it is the right site
C     = cellstr(cur_struct.site);
TEST  = sites(des_sites);
out   = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
if ~any(~cellfun(@isempty,out));
    error_msg    = {};
    error_msg{1} = ['The subject ' cur_struct.id ' from ' cur_struct.site '... is not from desired site! I will skip.'];
    disp(error_msg)
    return
end

% prep the preprocessing for the desired tasks
all_fields = fieldnames(cur_struct);

% initialize the error message
error_msg        = {};
err_ct           = 0 ;
seriesok         = 0;
t1ok             = 0;
for ff = 1:length(all_fields)
    % fields that are not for preprocessing
    C         = cellstr(all_fields(ff));
    TEST      = {'id','log','site'};
    out       = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_out = ~any(~cellfun(@isempty,out));
    
    % test if from a desired task
    C        = cellstr(all_fields(ff));
    TEST     = tasks(des_tasks);
    out      = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_in = any(~cellfun(@isempty,out));
    
    if do_it_in && do_it_out
        % this is a desired task series
        % get some checks
        test_res = 0;
        
        % print some empty lines to have better visibility
        disp(' ')
        disp(' ')
        
        % check dcms
        cur_dcm = getfield(cur_struct,all_fields{ff});
        if isempty(cur_dcm)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... had no dicoms, so cannot have niftis!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % we just check quickly if everything is there
        % get into the folder
        cur_ss_dir = fullfile(base_dir_pl,cur_struct.id,all_fields{ff},'niftis');
        
        if ~exist(cur_ss_dir)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} ' directory does not exist. Copy it back! Skipping.'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % check for results
        cd(cur_ss_dir)
        cd ..
        cd results
        if ~exist('ss_design_00')
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} ' ss_design_00 directory does not exist. Skipping'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % check if ss_design_00 is okay
        cd ss_design_00
        cur_cons = cellstr(ls('con_00*.nii'));
        if ~length(cur_cons) > 4
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} ' ss_design_00 does not have at least 5 cons. Skipping'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % if here then you are good
        test_res = 1;
        
        % note down the folder that needs to be copied
        ss_folder = pwd;
        
        if all(test_res)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been correctly written!'];
            ssok    = 1;
        else
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has not been correctly written!'];
            ssok    = 0;
        end
        
        [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
        
        % I will copy
        if ssok
            disp(['Copying the subject ' cur_struct.id ' series ' all_fields{ff} ' ss_model_00!'])

            % ss folder
            cur_src = ss_folder;
            cur_trg = strrep(ss_folder,'L:\NGFN','E:\NGFN');
            [tp, tf, te] = fileparts(cur_trg);
            if ~exist(tp)
                mkdir(tp)
            end
            copyfile(cur_src,cur_trg,'f')
            
            % leave a note
            disp('Leaving note')
            [tp, tf, te] = fileparts(cur_trg);
            cur_note     = fullfile(tp,'ss_model_00_correct_and_copied.txt');
            fid          = fopen(cur_note,'w');
            fclose(fid);
            
            % record message
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... ss_model_00 has been copied!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            
            % print some empty lines to have better visibility
            disp(' ')
            disp(' ')
        end

    end
end

    function [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg)
        err_ct            = err_ct + 1;
        error_msg{err_ct,1} = cur_msg;
        disp(error_msg{err_ct})
    end


end