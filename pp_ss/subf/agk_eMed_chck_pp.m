function error_msg = agk_eMed_chck_pp(cur_struct,base_dir_pl,des_tasks,tasks,des_sites,sites)
% function that checks the pp (what is done)
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
            t1_pp_musts   = {fullfile(pt1, ['y_r' ft1 et1]); ... 
                fullfile(pt1, ['r' ft1 et1]); fullfile(pt1, ['wc1r' ft1 et1]); ...
                fullfile(pt1, ['wc2r' ft1 et1]); fullfile(pt1, ['mwc1r' ft1 et1]); ...
                fullfile(pt1, ['mwc2r' ft1 et1]); fullfile(pt1, ['swc1r' ft1 et1]); ...
                fullfile(pt1, ['smwc1r' ft1 et1]);fullfile(pt1, ['swc2r' ft1 et1]); ...
                fullfile(pt1, ['smwc2r' ft1 et1])};
            
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
            continue
        end
        
        % check if logfile is there
        if isempty(getfield(cur_struct,[all_fields{ff} '_log']))
            cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no logfiles! I will skip for now.'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        % use the dcmHeader info
        cur_src_dir = fullfile(base_dir_pl,cur_struct.id,all_fields{ff},'niftis');
        
        if ~exist(cur_src_dir)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} 'directory does not exist. Copy it back! Skipping.'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        
        cd(cur_src_dir)
        if exist('dcmHeaders.mat')
            load('dcmHeaders.mat')
        else
            cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no dcmHeaders! I will skip for now.'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        allfields   = fieldnames(h);
        h           = getfield(h,allfields{1});
        
        % check for slice timing field
        if isfield(h,'MosaicRefAcqTimes')
            sliceTiming = (h.MosaicRefAcqTimes);
        elseif isfield(h,'RefAcqTimes')
            sliceTiming = (h.RefAcqTimes);
        else
            cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no slice timing info in dcmHeaders! I will skip for now.'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        nslices     = length(sliceTiming);
        tr          = h.RepetitionTime/1000;
        so          = sliceTiming;
        ta          = tr-(tr/nslices);
        
        % check if this is a valid sliceTiming vector
        if (length(sliceTiming) <= 42 && all(sliceTiming >= 0))
            % great this seems to be a valide sliceTimes vector
            validSt = 1;
        else
            % not sliceTimes vector
            cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no valid SliceTimes; nslices: ' num2str(length(sliceTiming))];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            validSt = 0;
            so      = [];
            nslices = [];
            % for now continue
            continue
        end
        
        % target nifti folder; get the niftis
        cur_src_dir = fullfile(base_dir_pl,cur_struct.id,all_fields{ff},'niftis');
        cd(cur_src_dir)
        % get the nifti name
        load('dcmHeaders.mat')
        allfields = fieldnames(h);
        st_scans = cellstr(ls([allfields{1} '*.nii']));
        if isempty(st_scans{1})
            cur_msg             = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no niftis!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            continue
        end
        st_scans = fullfile(cur_src_dir,st_scans);
        
        % another way of getting the slice order
        cur_so = get_nii_so(st_scans{10});
        
        if validSt
            % checking if the two so order fetching ways agree
            if cur_so == 2 && (sliceTiming(1) > sliceTiming(end))
                % descending sequential
                so       = sliceTiming;
                refslice = 0;
                nslices  = length(sliceTiming);
            elseif cur_so == 1 && (sliceTiming(1) < sliceTiming(end))
                % ascending sequential
                so       = sliceTiming;
                refslice = 0;
                nslices  = length(sliceTiming);
            else
                % not ok
                cur_msg             =  ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has mismatch slice order situation!'];
                [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
                continue
            end
        else
            cur_msg             =  ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no valid SliceTiming: so we trust the slice order; complete code!!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            % no valid SliceTiming: so we trust the slice order
            % complete later
        end
        
        % check if already preprocessed
        pp_files = cellstr(ls('swra*.nii'));
        if length(pp_files) == length(st_scans)
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been preprocessed!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
            seriesok = seriesok + 1;
            continue
        else
            cur_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has NOT been preprocessed!'];
            [error_msg, err_ct] = agk_err_msg_func(error_msg,err_ct,cur_msg);
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