%function [] = agk_eMed_pipeline_pp_ss_int3()
%% ############### PREAMBLE ########################
% ##################################################
% PIPELINE FOR RUNNING PREPROCESSING AND 1st LEVEL

% Author: Alexander Genauck
% Work address:
% email: alexander.genauck@charite.de
% Website:
% June 2018;

%------------- BEGIN CODE --------------
clear all
clear classes
%% ############### Generell Settings ###############
% add my lib
%start_up
addpath(genpath('C:\Users\agemons\Google Drive\Library\MATLAB'));
% where are the subject folders with MRI data?
% or this folder and its structure will be firstly created
base_dir_pl = 'L:\NGFN\pp1stL';
% Set spm mask threshold (for 1st level also important)
warning('Make sure that SPM mask threshold is at 0.2')
% path to struct that holds all path infos to subjects
path_struct = 'C:\Users\agemons\Google Drive\Library\MATLAB\eMed\pp_ss\ngfn_struct_paths_mri_dcm_NEW.mat';
if ~exist('paths')
    load(path_struct)
end

warning('suject 6 needs to get VR done and possibly other tasks; aka dcm2nii, pp, ss')

%% ################ PARAMS #########################
% what do we have in data?
tasks = {'t1','ALCUE','Faces','NBack','VR'};
sites = {'Berlin','Mannheim','Bonn'};

% what to run?
mfs         = 0; % make a folder structure
cpl         = 0; % copy the logfiles into the folder structure
d2n         = 0; % dicom 2 nifti
pp          = 0; % preprocessing
chckpp      = 0; % check pp
cpyppt1     = 1; % copy  pp t1 (copy to external hard drive for sambu)
ss_alc      = 0; % ss-level alcue
ss_faces    = 0; % ss-level faces
ss_nback    = 0; % ss-level nback
ss_vr       = 0; % ss-level vr
cpyss       = 1; % copy the ss models (copy to external hard drive for sambu)

% specific params for pp
do_run_pp     = 1; % if 0 then only the batch is written
allow_skip_pp = 1; % allows the skipping of slice timing and realignement of epis, if done already
ow_pp         = 1; % allows overwriting pp despite already pp done; but only of ss epis; if t1 pp there; it will be used
ow_pp_t1      = 0; % hard overwrite pp; t1 pp will be deleted and estimated anew; epis will be aligned to the t1
allow_cut     = 1; % beyond allow_skip_pp, this is to allow the cutting of t1 pp; 1, if t1 pp already done (in ALCUE);

% specific params for ss
ow_ss         = 1; % overwrite an already estimated ss model (SPM.mat)?

% what to run in tasks sites subs? if [], then all
% des_subs used in pp and ss
% des_tasks and des_sites only in pp
% Bonn makes problems! d2n!

des_subs  = [];                % redo subs
des_tasks = [3:4];             % first ALCUE needs to be fine for all
des_sites = [1:3];             % all now

% parallel pool
M = 12;

%% ############### PROCESSING PREPS ################
% running on spm12
which_spm(12,'genaucka',1)

%% ############### MAKE A FOLDER STRUCTURE #########
if mfs
    % creates a folder structure where Niftis and logfiles will be put in
    mkdir(base_dir_pl)
    if isempty(des_subs), des_subs = 1:length(paths); end
    for ss = des_subs
        cd(base_dir_pl)
        agk_eMed_pp_create_foldstr(paths(ss),base_dir_pl)
    end
end

%% ############### COPY LOGFILES PREPS ##############
if cpl
    % done for all except VR
    % copy the logfiles where they belong
    mkdir(base_dir_pl)
    if isempty(des_subs), des_subs = 1:length(paths); end
    for ss = des_subs
        cpl_feedback = agk_eMed_cp_logfiles(paths(ss),base_dir_pl,des_tasks,tasks,des_sites,sites);
        cd(base_dir_pl)
        save('cpl_feedback','cpl_feedback')
    end
    
end

%% ############### DICOM2NIFTI #####################
if d2n
    % dicom2nifti convert from source to target
    % source are dicoms whose provenance is given in the paths struct
    % creates a folder structure where Niftis and logfiles will be put in
    mkdir(base_dir_pl)
    if isempty(des_subs), des_subs = 1:length(paths); end
    cur_paths = load(path_struct);
    paths = cur_paths.paths;
    parfor (ss = des_subs,M)
        cd(base_dir_pl)
        cur_paths = paths(ss);
        d2n_feedback{ss} = agk_eMed_wrapper_dcm2nifti(cur_paths,base_dir_pl);
        cd(base_dir_pl)
    end
end

%% ############### PREPROCESS #######################
if pp
    % preprocess convert from source to target
    % source are dicoms whose provenance is given in the paths struct
    % creates a folder structure where Niftis and logfiles will be put in
    %     if isempty(des_subs)
    %         des_subs = 1:length(paths);
    %     else
    %         paths = paths(subs_to_redo);
    %         des_subs = 1:length(paths);
    %     end
    if isempty(des_subs)
        des_subs = 1:length(paths);
    end
    parfor (ss = des_subs,M)
        cd(base_dir_pl)
        cur_paths = paths(ss);
        agk_eMed_subf_pp(cur_paths,base_dir_pl,des_tasks,tasks,des_sites,sites,do_run_pp,allow_skip_pp,ow_pp,allow_cut,ow_pp_t1);
        cd(base_dir_pl)
    end
end

%% ############### CHECK PP #########################
if chckpp
    % preprocess convert from source to target
    % source are dicoms whose provenance is given in the paths struct
    % creates a folder structure where Niftis and logfiles will be put in
    if isempty(des_subs), des_subs = 1:length(paths); end
    error_msg = {};
    for ss = des_subs
        cd(base_dir_pl)
        cur_paths = paths(ss);
        error_msg{ss} = agk_eMed_chck_pp(cur_paths,base_dir_pl,des_tasks,tasks,des_sites,sites);
        cd(base_dir_pl)
    end
    
    % copy it back problem
    subs_to_redo = [];
    for ee = 1:length(error_msg)
        test_1 = ~all(cellfun(@isempty,strfind(error_msg{ee},'Copy it back')));
        test_2 = ~all(cellfun(@isempty,strfind(error_msg{ee},'t1 NOT correctly pp''d')));
        
        if (test_1 || test_2) || (test_1 && test_2)
            subs_to_redo = [subs_to_redo ee];
        end
    end
    
end

%% ############### COPY T1 PP #######################
if cpyppt1
    if isempty(des_subs), des_subs = 1:length(paths); end
    error_msg_t1 = {};
    for ss = des_subs
        cd(base_dir_pl)
        cur_paths = paths(ss);
        error_msg_t1{ss} = agk_eMed_copy_pp(cur_paths,base_dir_pl,des_tasks,tasks,des_sites,sites);
        cd(base_dir_pl)
    end    
end

%% ############### ss-LEVEL ALCUE ###################
if ss_alc
    % ss level estimation
    if isempty(des_subs)
        des_subs = 1:length(paths);
    end
    parfor (ss = des_subs,M)
        cd(base_dir_pl)
        cur_paths = paths(ss);
        agk_emed_ss_alcue(cur_paths,ow_ss);
        cd(base_dir_pl)
    end
end

%% ############### ss-LEVEL FACES ###################
if ss_faces
    % ss level estimation
    if isempty(des_subs)
        des_subs = 1:length(paths);
    end
    parfor (ss = des_subs,M) %ss = des_subs 
        cd(base_dir_pl)
        cur_paths = paths(ss);
        agk_emed_ss_faces(cur_paths);
        cd(base_dir_pl)
    end
end

%% ############### ss-LEVEL NBack ###################
if ss_nback
    % ss level estimation
    if isempty(des_subs)
        des_subs = 1:length(paths);
    end
    parfor (ss = des_subs,M)
        cd(base_dir_pl)
        cur_paths = paths(ss);
        agk_emed_ss_nback(cur_paths);
        cd(base_dir_pl)
    end
end

%% ############### ss-LEVEL VR ######################
if ss_vr
    % ss level estimation
    if isempty(des_subs)
        des_subs = 1:length(paths);
    else
        paths = paths(subs_to_redo);
        des_subs = 1:length(paths);
    end
    %parfor (ss = des_subs,M)
    ss=35;
        cd(base_dir_pl)
        cur_paths = paths(ss);
        agk_emed_ss_vr(cur_paths);
        cd(base_dir_pl)
    %end
end

%% ############### COPY SS #########################
if cpyss
    if isempty(des_subs), des_subs = 1:length(paths); end
    error_msg_t1 = {};
    for ss = des_subs
        cd(base_dir_pl)
        cur_paths = paths(ss);
        error_msg_t1{ss} = agk_eMed_copy_ss(cur_paths,base_dir_pl,des_tasks,tasks,des_sites,sites);
        cd(base_dir_pl)
    end    
end
