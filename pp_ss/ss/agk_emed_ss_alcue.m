function agk_emed_ss_alcue(cur_paths,ow_ss)

try
    % get nifti folder, log file
    cd(cur_paths.id)
    cd('ALCUE')
    root         = pwd;
    nifti_folder = fullfile(pwd,'niftis');
    cd('logfiles')
    cur_log      = cellstr(ls('*_ALCUE.txt'));
    assert(length(cur_log) == 1)
    assert(~isempty(cur_log{1}));
    cur_log      = fullfile(pwd,cur_log);
    log_file     = cur_log{1};
    
    % read the log file
    fid = fopen(log_file);
    tline = fgetl(fid);
    all_lines = {};
    ct = 0;
    while ischar(tline)
        ct = ct + 1;
        all_lines{ct,1} = tline;
        tline = fgetl(fid);
    end
    
    fclose(fid);
    
    % parse the log file
    header     = all_lines{1};
    time_0     = str2double(all_lines{2});
    onset_data = all_lines(3:end,1);
    header     = strsplit(header,'\t');
    for ll = 1:length(onset_data)
        header = [header;strsplit(onset_data{ll,:},'\t')];
    end
    onset_data = cell2table(header(2:end,:),'VariableNames',header(1,:));
    
    % get the onset names
    des_cat       = {'neutral','beer','wine','schnapps'}';
    cat_names     = unique(onset_data.category);
    assert(length(cat_names) == 4)
    for dd = 1:length(des_cat)
        assert(~isempty(strfind(cat_names,des_cat{dd})))
    end
    cat_names     = des_cat;
    cat_names_rat = strcat(cat_names,'_rating_start');
    cat_names     = [cat_names;cat_names_rat];
    
    % get onsets, durations
    cat_onsets    = {};
    cat_durations = {};
    for cc = 1:length(cat_names)
        cur_cat       = cat_names{cc};
        cur_onsets    = [];
        cur_durations = [];
        if isempty(strfind(cur_cat,'rating'))
            % cue reactivity case
            ind     = find(~cellfun(@isempty,strfind(onset_data.category,cur_cat)));
            cod     = onset_data(ind,:);
            % get the onset times
            for oo = 1:length(cod{:,1})
                cur_onsets(oo)    = str2double(cod.block_start{oo})  - time_0;
                cur_durations(oo) = str2double(cod.block_end{oo}) - time_0 - cur_onsets(oo);
            end
        else
            % rating case
            cur_cat_pure = strsplit(cur_cat,'_');
            cur_cat_pure = cur_cat_pure{1};
            ind     = find(~cellfun(@isempty,strfind(onset_data.category,cur_cat_pure)));
            cod     = onset_data(ind,:);
            % get the onset times
            for oo = 1:length(cod{:,1})
                cur_onsets(oo)    = str2double(cod.rating_start{oo}) - time_0;
                cur_durations(oo) = str2double(cod.rating_end{oo}) - time_0   - cur_onsets(oo);
            end
        end
        
        % correct to seconds
        cur_onsets    = cur_onsets/1000;
        cur_durations = cur_durations/1000;
        % collect
        cat_onsets    = [cat_onsets,cur_onsets];
        cat_durations = [cat_durations,cur_durations];
    end
    
    % save the mult_cond.mat
    onsets    = cat_onsets;
    durations = cat_durations;
    names     = cat_names';
    cd(fullfile(root,'results'))
    mkdir('ss_design_00')
    cd('ss_design_00')
    
    % check if already done
    if exist('SPM.mat') && ow_ss == 0
        con_images = cellstr(ls('con_*.nii'));
        if length(con_images) == 10
            disp('ss model already run. skipping')
            return
        end
    end
    
    save('mult_cond.mat','onsets','names','durations')
    ss_dir         = pwd;
    mult_cond_file = cellstr(fullfile(ss_dir,'mult_cond.mat'));
    
    % get the scans
    cd(nifti_folder)
    niftis = cellstr(ls('sw*.nii'));
    niftis = fullfile(pwd,niftis);
    
    % the realignment file
    cd(nifti_folder);
    rp_file = cellstr(fullfile(pwd,ls('rp_*.txt')));
    
    % get the RT, microtime resolution
    % sort pp batches from oldes to youngest
    pp_batch = dir('preprocess_batch*.mat');
    assert(length(pp_batch) >= 1);
    [~,idx]  = sort([pp_batch.datenum]);
    pp_batch = pp_batch(idx); 
    cur_tr = [];
    mtr    = [];
    for pp = 1:length(pp_batch)
        cur_batch = load(pp_batch(pp).name);
        try
            cur_tr   = cur_batch.matlabbatch{1}.spm.temporal.st.tr;
            mtr      = cur_batch.matlabbatch{1}.spm.temporal.st.nslices;
            ind_btch = pp;
        catch
        end
    end
    
    assert(~isempty(cur_tr))
    assert(~isempty(mtr))
    
    % get reference slice
    % testing that not slice order but ms were used in preprocessing
    cur_batch = load(pp_batch(ind_btch).name);
    x         = cur_batch.matlabbatch{1}.spm.temporal.st.so;
    assert(max(x) > 1000)
    cur_ref   = cur_batch.matlabbatch{1}.spm.temporal.st.refslice;
    cur_t0    = find(cur_batch.matlabbatch{1}.spm.temporal.st.so == cur_ref);
    assert(~isempty(cur_t0))
        
    % make a matlabbatch
    matlabbatch                                       = [];
    matlabbatch{1}.spm.stats.fmri_spec.dir            = {ss_dir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units   = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = cur_tr;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = mtr;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = cur_t0;
    %%
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = niftis;
    %%
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = mult_cond_file;
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress   = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = rp_file;
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.2;
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Cue.beer';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [-1 1];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Cue.wine';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [-1 0 1];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'Cue.schnapps';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [-1 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'Cue.alc';
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [-3 1 1 1];
    matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'Rat.beer';
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 -1 1];
    matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'Rat.wine';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [0 0 0 0 -1 0 1];
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'Rat.schnapps';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 0 0 0 -1 0 0 1];
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'Rat.alc';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = [0 0 0 0 -3 1 1 1];
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'Cue.alc.lin';
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = [0 1 2 3];
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.name = 'Rat.alc.lin';
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.weights = [0 0 0 0 0 1 2 3];
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.delete = 0;
    
    % save matlabbatch
    cd(ss_dir)
    save('design.mat','matlabbatch')
    
    % run the ss level
    cd(ss_dir)
    spm_jobman('run','design.mat')
catch
    disp('Something went wrong. Skipping!')
end

