function agk_emed_ss_nback(cur_paths,ow_ss)

try
    % get nifti folder, log file
    cd(cur_paths.id)
    cd('NBack')
    root         = pwd;
    nifti_folder = fullfile(pwd,'niftis');
    cd('logfiles')
    cur_log      = cellstr(ls('*nback.xls'));
    assert(length(cur_log) == 1)
    assert(~isempty(cur_log{1}));
    cur_log      = fullfile(pwd,cur_log);
    log_file     = cur_log{1};
    
    % extract info from logfile
    out = extract_soa(log_file);
    
    % save the mult_cond.mat
    onsets    = out.mult_cond_mat.onsets;
    durations = out.mult_cond_mat.durations;
    names     = out.mult_cond_mat.names;
    cd(fullfile(root,'results'))
    mkdir('ss_design_00')
    cd('ss_design_00')
    
    % check if already done
    if exist('SPM.mat') && ow_ss == 0
        con_images = cellstr(ls('con_*.nii'));
        if length(con_images) == 5
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
    % contrasts
    % F
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = out.all_con_names{1};
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = out.all_contrasts{1};
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'replsc';
    % T
    for cc = 2:length(out.all_contrasts)
        matlabbatch{3}.spm.stats.con.consess{cc-1}.tcon.name = out.all_con_names{cc};
        matlabbatch{3}.spm.stats.con.consess{cc-1}.tcon.weights = out.all_contrasts{cc};
        matlabbatch{3}.spm.stats.con.consess{cc-1}.tcon.sessrep = 'replsc';
    end
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


    function out = extract_soa(log_file)
        %% extract soa
        
        % read in log file
        fid = fopen(log_file);
        log_data = textscan(fid,'%s %s %s %s %s %s %s %s %*[^\n]','delimiter','\t');
        fclose(fid);
        log_data = [log_data{:}];
        
        warning('DATE-TIME SERIES,BEHAVIOR,LOGFILE PLAUSIBILITY CHECK TURNED OFF')
        % CAREFUL: I took out the whole plausibility check of time and date,
        % that Torsten did
        plausible = true;
        
        if plausible == true
            % search relevant colums
            for ii = 1:size(log_data,2)
                if strcmpi(char(log_data(3,ii)),'event type') type_col = ii; end
                if strcmpi(char(log_data(3,ii)),'code') code_col = ii; end
                if strcmpi(char(log_data(3,ii)),'time') soa_col = ii; end
                if strcmpi(char(log_data(3,ii)),'duration') dur_col = ii; end
            end
            
            % extract design information for current series from configuration structure
            log_codes = {'num','2back','0back','1','2','3','4'};
            exp_types = {'stim','cue','cue','resp','resp','resp','resp'};    
            exp_logic = {[1 2 0],[1 3 0],[0 2 0],[0 3 0],[0 2 4; 0 2 5; 0 2 6; 0 2 7; 0 3 4; 0 3 5; 0 3 6; 0 3 7]};            
            names     = {'2-back','0-back','cue(2-back)','cue(0-back)','response'};          
            EoI       = [1 2];
            cons      = {'C{1}-C{2}'};

            % first MRI pulse - reference point in time
            first_pulse = [];
            % flag for currently active cue or task respectively
            current_cue = NaN;
            % code matrix, later analyzed with exp_logic rules specified in configuration file
            X = NaN(size(log_data,1),5);
            % loop over all logfile entries
            for ii = 1:size(log_data,1)
                % searching the first MRI pulse
                if strcmpi(char(log_data(ii,type_col)),'pulse')
                    disp('Found fMRI pulse')
                    if isempty(first_pulse)
                        disp('Recorded first fMRI pulse')
                        first_pulse = str2double(char(log_data(ii,soa_col)));
                    end
                else
                    % process logfile lines only in case of running MRI experiment (after first MRI pulse)
                    if ~isempty(first_pulse)
                        for jj = 1:numel(log_codes)
                            % in case of accordance modify code matrix
                            if strcmpi(char(log_data(ii,type_col)),'response')
                                disp('Found a response')
                                if strcmpi(char(log_data(ii,code_col)),char(log_codes(jj)))
                                    X(ii,3) = jj;
                                    X(ii,4) = str2double(char(log_data(ii,soa_col)));
                                    X(ii,5) = 0;
                                end
                            else
                                if ~isempty(strfind(lower(char(log_data(ii,code_col))),lower(char(log_codes(jj)))))
                                    if strcmpi(char(exp_types(jj)),'stim')
                                        disp('Found a stim')
                                        X(ii,1) = jj;
                                    end;
                                    if strcmpi(char(exp_types(jj)),'cue')
                                        disp('Found a cue')
                                        X(ii:end,2) = jj;
                                    end;
                                    X(ii,4) = str2double(char(log_data(ii,soa_col)));
                                    X(ii,5) = str2double(char(log_data(ii,dur_col)));
                                end
                            end
                        end
                    end
                end
            end
            
            % reduce design matrix
            X = X(~isnan(X(:,4)),:);
            X(:,4) = (X(:,4)-first_pulse)/10000;
            X(:,5) = X(:,5)/10000;
            X(isnan(X)) = 0;
            
            % analyze design matrix
            onsets = cell(size(names));
            durations = cell(size(names));
            for ii = 1:numel(exp_logic)
                search_for = exp_logic{ii}; %eval(char(exp_logic(ii)));
                for jj = 1:size(X,1)
                    found = false;
                    for kk = 1:size(search_for,1)
                        if sum(X(jj,1:3) == search_for(kk,:)) == 3
                            found = true;
                        end
                    end
                    if found == true;
                        onsets{ii}(numel(onsets{ii})+1) = X(jj,4);
                        durations{ii}(numel(durations{ii})+1) = X(jj,5);
                    end
                end
            end
            % create contrasts
            % baseline T-contrasts
            C = cell(1,numel(names));
            for ii = 1:numel(names)
                C{ii} = zeros(1,numel(names));
                C{ii}(ii) = 1;
            end
            % differential T-contrasts
            CD = cell(1,numel(cons));
            for ii = 1:numel(cons)
                CD{ii} = eval(char(cons(ii)));
            end
            % effects of interest F-contrast
            CE = {zeros(numel(names))};
            for ii = 1:numel(EoI)
                CE{1}(EoI(ii),EoI(ii)) = 1;
            end
            % concatenate to final contrast cell array
            all_contrasts = [CE C CD];
            save('mult_cond.mat','names','onsets','durations');
            
            % prepare an output struct
            mult_cond_mat.names     = names;
            mult_cond_mat.onsets    = onsets;
            mult_cond_mat.durations = durations;
            
            out.mult_cond_mat       = mult_cond_mat;
            out.all_contrasts       = all_contrasts;
            out.all_con_names       = {'EOI','2back','0-back', ...
                                       'cue2back','cue0back', ...
                                       'response','2back-0back'};
        end
    end

end

