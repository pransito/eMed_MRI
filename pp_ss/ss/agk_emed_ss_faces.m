function agk_emed_ss_faces(cur_paths,ow_ss)

try
    % get nifti folder, log file
    cd(cur_paths.id)
    cd('FACES')
    root         = pwd;
    nifti_folder = fullfile(pwd,'niftis');
   
    % creat results folder
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
    
    ss_dir         = pwd;
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
    
    %% make a matlabbatch
    matlabbatch                                       = [];
    matlabbatch{1}.spm.stats.fmri_spec.dir            = {ss_dir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units   = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = cur_tr;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = mtr;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = cur_t0;
    %
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans     = niftis;
    %
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'faces';
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = [42
        106
        170
        234];
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = 30;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'shapes';
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = [10
        74
        138
        202];
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = 30;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod     = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth     = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).name     = 'cue';
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).onset    = [8
        40
        72
        104
        136
        168
        200
        232];
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).duration = 2;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).tmod     = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).pmod     = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).orth     = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi            = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress          = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg        = rp_file;
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf              = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact                  = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs      = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt                  = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global                = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh               = 0.2;
    matlabbatch{1}.spm.stats.fmri_spec.cvi                   = 'AR(1)';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1)              = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals        = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical       = 1;
    % contrasts
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'EOI';
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = [1 0
        0 1];
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{2}.fcon.name = 'F (faces)';
    matlabbatch{3}.spm.stats.con.consess{2}.fcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{2}.fcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{3}.fcon.name = 'F (Shapes)';
    matlabbatch{3}.spm.stats.con.consess{3}.fcon.weights = [0 1];
    matlabbatch{3}.spm.stats.con.consess{3}.fcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{4}.fcon.name = 'F (cues)';
    matlabbatch{3}.spm.stats.con.consess{4}.fcon.weights = [0 0 1];
    matlabbatch{3}.spm.stats.con.consess{4}.fcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{5}.fcon.name = 'HE Bedingung';
    matlabbatch{3}.spm.stats.con.consess{5}.fcon.weights = [1 -1];
    matlabbatch{3}.spm.stats.con.consess{5}.fcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'T (Faces)';
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'T (Shapes)';
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 1];
    matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'T (cues)';
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = [0 0 1];
    matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'T (Faces > Shapes)';
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = [1 -1];
    matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.name = 'T (Faces < Shapes)';
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.weights = [-1 1];
    matlabbatch{3}.spm.stats.con.consess{10}.tcon.sessrep = 'none';
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

