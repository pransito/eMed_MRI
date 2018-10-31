%-----------------------------------------------------------------------
% Job saved on 12-Jun-2018 11:49:04 by cfg_util (rev $Rev: 6942 $)
% spm SPM - SPM12 (7219)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.stats.fmri_spec.dir = '<UNDEFINED>';
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
matlabbatch{1}.spm.stats.fmri_spec.sess.scans = '<UNDEFINED>';
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
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 1;
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).name = 'cue';
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).onset = [8
                                                         40
                                                         72
                                                         104
                                                         136
                                                         168
                                                         200
                                                         232];
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).duration = 2;
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).tmod = 0;
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).orth = 1;
matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = '<UNDEFINED>';
matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.2;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
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
