% make from matlabbatch faces a mult_cond file

rootPath = 'G:\NGFN\fMRI_Faces\Faces_Logfiles';

cd(rootPath)

condInfo = matlabbatch{2}.spm.stats.fmri_spec.sess.cond;

% init
pmod = [];

% names, onsets, durations, orth
for mm = 1:length(condInfo)
    names{mm}     = condInfo(mm).name;
    onsets{mm}    = condInfo(mm).onset;
    durations{mm} = condInfo(mm).duration;
    orth{mm}      = 1;
    pmod(mm).name  = {};
    pmod(mm).param = {};
    pmod(mm).poly  = {};
end

% saving
save('mult_cond.mat','names','onsets','durations','orth','pmod')