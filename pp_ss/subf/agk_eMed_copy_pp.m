function error_msg = agk_eMed_copy_pp(cur_struct,base_dir_pl,des_tasks,tasks,des_sites,sites)
% function that copies the t1's
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
        % this is a desired task series, t1
        % check dcms
        cur_dcm = getfield(cur_struct,all_fields{ff});
        if isempty(cur_dcm)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... had no dicoms, so cannot have niftis!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % if t1 we just check quickly if everything is there
        if strcmp(all_fields{ff},'t1')
            % get into the folder
            cur_t1_dir = fullfile(base_dir_pl,cur_struct.id,all_fields{ff},'niftis');
            
            if ~exist(cur_t1_dir)
                cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} 'directory does not exist. Copy it back! Skipping.'];
                [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
                continue
            end
            
            cd(cur_t1_dir)
            
            % check for t1 image
            cur_t1     = cellstr(ls('t1_mpr*.nii'));
            
            if length(cur_t1) > 1
                cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has mult t1, took first one!'];
                [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            end
            
            if isempty(cur_t1{1})
                cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no t1! No further tests!'];
                [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
                return
            end
            
            % check for pp t1 images
            cur_t1        = cur_t1{1};
            cur_t1        = fullfile(pwd,cur_t1);
            [pt1,ft1,et1] = fileparts(cur_t1);
            t1_pp_musts   = {fullfile(pt1, ['y_' ft1 et1]); ... 
                fullfile(pt1, [ft1 et1]); fullfile(pt1, ['wc1' ft1 et1]); ...
                fullfile(pt1, ['wc2' ft1 et1]); fullfile(pt1, ['mwc1' ft1 et1]); ...
                fullfile(pt1, ['mwc2' ft1 et1]); fullfile(pt1, ['swc1' ft1 et1]); ...
                fullfile(pt1, ['smwc1' ft1 et1]);fullfile(pt1, ['swc2' ft1 et1]); ...
                fullfile(pt1, ['smwc2' ft1 et1])};
            
            test_res  = [];
            for tt = 1:length(t1_pp_musts)
                test_res = [test_res exist(t1_pp_musts{tt})];
            end
            
            if all(test_res)
                cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has t1 correctly pp''d!'];
                t1ok    = 1;
            else
                cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has t1 NOT correctly pp''d!'];
                t1ok    = 0;
            end
            
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            
            % I will copy
            if t1ok
                disp(['Copying the subject ' cur_struct.id ' series ' all_fields{ff} ' PP!'])
                t1_pp_musts = [t1_pp_musts; cur_t1];
                    
                % pp'd t1
                for tt = 1:length(t1_pp_musts)         
                    % pp'd t1
                    cur_src = t1_pp_musts{tt};
                    cur_trg = strrep(t1_pp_musts{tt},'L:\NGFN','E:\NGFN');
                    [tp, tf, te] = fileparts(cur_trg);
                    if ~exist(tp)
                        mkdir(tp)
                    end
                    copyfile(cur_src,cur_trg,'f')
                end
                
                % leave a note
                disp('Leaving note')
                [tp, tf, te] = fileparts(cur_trg);
                cur_note     = fullfile(tp,'t1_pp_correct_and_copied.txt');
                fid          = fopen(cur_note,'w');
                fclose(fid);
                
                % record message
                cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been copied!'];
                [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            end
            
            continue
        else
            % other series to skip
            continue
        end
    end
end

if t1ok && seriesok == 4
    error_msg    = {};
    cur_msg      = ['The subject ' cur_struct.id '... has t1 and all 4 series correctly preprocessed!'];
    error_msg{1} = cur_msg;
    disp(cur_msg)
end

    function [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg)
        err_ct            = err_ct + 1;
        error_msg{err_ct,1} = cur_msg;
        disp(error_msg{err_ct})
    end


end