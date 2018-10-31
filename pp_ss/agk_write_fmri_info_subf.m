function [] = agk_write_fmri_info_subf(is)

% meta
fid = fopen('fMRI_params_from_phoenix_pdf.txt','w');
fprintf(fid,['Study date: ' is.cur_sd '\n']);
fprintf(fid,['Study time:' is.cur_st '\n']);
fprintf(fid,['Series date:' is.cur_sed '\n']);
fprintf(fid,['Series time:' is.cur_set '\n']);
fprintf(fid,['Subject: ' is.cur_sub '\n']);
fprintf(fid,['Subject birth date: ' is.cur_bd '\n']);
fprintf(fid,['Series description:' is.cur_sen '\n']);

% sequence
fprintf(fid,['Repetition time (ms): ' is.cur_tr '\n']);
fprintf(fid,['Echo time[0] (ms): ' is.cur_et '\n']);
fprintf(fid,['Flip angle: ' is.cur_fa '\n']);
fprintf(fid,['Slice thickness (mm): ' is.cur_st '\n']);
fprintf(fid,['Slice spacing (mm): ' is.cur_ss '\n']);
fprintf(fid,['Voxel size x (mm): ' is.cur_sx '\n']);
fprintf(fid,['Voxel size y (mm): ' is.cur_sy '\n']);
fprintf(fid,['Number of volumes:  ' is.cur_nv '\n']);
fprintf(fid,['Number of slices: ' is.cur_ns '\n']);

fprintf(fid,['Multi-slice mode: ' is.cur_ms '\n']);
fprintf(fid,['Acquisition order: ' is.cur_ao '\n']);

fclose(fid);