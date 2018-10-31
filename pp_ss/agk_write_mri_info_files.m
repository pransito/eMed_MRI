% writes a text file for each task/subject
% with MRI params

% need an exclusion list for PTB old still
% where are the logfiles of behav?
% need to read out meta data still

% Berlin only
root   = 'E:\ngfn';
%root     = 'S:\AG\AG-Emotional-Neuroscience-Backup\NGFN';
tasks    = {'fMRI_ALCUE','fMRI_Faces','fMRI_NBack','fMRI_VR'};
spss     = ['S:/AG/AG-Emotional-Neuroscience-Backup/NGFN/' ...
    'SPSS-Datenmasken/Datenmasken_FINALs/Berlin/' ...
    'spss_bln.csv'];
spss_tab = readtable(spss,'Delimiter','\t');
cur_p    = pwd;
addpath(cur_p);

for tt = 1:length(tasks)
    cur_path = fullfile(root,tasks{tt});
    cd(cur_path)
    cd(ls('*_Nifti'))
    cd('Berlin')
    cur_task = strsplit(tasks{tt},'_');
    all_subs = cellstr(ls(['*' cur_task{2} '*']));
    cur_home = pwd;
    for ss = 1:length(all_subs)
        cd(cur_home)
        cd(all_subs{ss})
        
        % delete one falsely written text file
        if ~isempty(ls('*_pdf.txt'))
            delete(ls('*_pdf.txt'))
        end
        
        % check if there is already and info text
        % in two tasks we need to go one folder lower
        IndexC = strfind({'fMRI_Faces','fMRI_NBack','fMRI_VR'}, tasks{tt});
        Index  = find(not(cellfun('isempty', IndexC)));
        if ~isempty(Index)
            cd(ls('*_ep2d_*'))
        end
        
        % now check for the text file
        all_files = cellstr(ls());
        is_there  = strfind(all_files,'_info.txt');
        is_there  = not(cellfun('isempty', is_there));
        is_there  = any(is_there);
        
        % decide what to do, if text file is there or not
        if strcmp(tasks{tt},'fMRI_NBack') && ~is_there
            error('fMRI_NBack but no fMRI info text file')
        end
        if (is_there)
            disp('Info text file is there. I will continue.')
            continue
        end
        
        % if not, we will write one
        cur_sub    = strsplit(all_subs{ss},'_');
        cur_sub    = [cur_sub{1} '_' cur_sub{2} '_' cur_sub{3}];
        is.cur_sub = cur_sub;
        
        % find infos on subject
        sub_where = strfind(spss_tab.ID,cur_sub);
        sub_where = find(not(cellfun('isempty', sub_where)));
        
        % meta params
        is.cur_sd  = spss_tab.scandate{sub_where}; % study date
        is.cur_st  = spss_tab.scantime{sub_where}; % study time
        is.cur_sed = is.cur_sd;                    % series date
        is.cur_set = is.cur_sd;                    % series time
        is.cur_sub = cur_sub;                      % subject
        is.cur_bd  = spss_tab.birth{sub_where};    % subject birthday
        
        if strcmp(tasks{tt},'fMRI_ALCUE')
            % fMRI params
            is.cur_tr = num2str(2410);                 % repetition time
            is.cur_et = num2str(25);                   % echo time
            is.cur_st = num2str(2);                    % slice thickness
            is.cur_ss = num2str(125/42);               % slice spacing
            is.cur_fa = num2str(80);                   % flip angle
            is.cur_sx = num2str(192/64);               % voxel size x
            is.cur_sy = num2str(192/64);               % voxel size y
            is.cur_nv = num2str(305);                  % number of volumes
            is.cur_ns = num2str(42);                   % number of slices
            is.cur_ms = 'Interleaved';                 % multi-slice mode
            is.cur_ao = 'Descending';                  % acquisition order
            is.cur_sen = 'ep2d_bold_mos_ALCUE_Grappa'; % series description
            
        elseif strcmp(tasks{tt},'fMRI_Faces')
            % reference dicom
            ref_dcm = fullfile(root,['Linda_Faces\Faces\102_1_163_Faces fmri_F10.2\' ...
                'epi\102_1_163-0005-0011.dcm']);
            cur_dcm = dicominfo(ref_dcm);
            
            % reference nifti
            all_niftis = cellstr(ls('*.nii'));
            ref_nifti = spm_vol(all_niftis{10});
            
            % meta
            is.cur_sd  = cur_dcm.AcquisitionDate;      % study date
            is.cur_st  = cur_dcm.AcquisitionTime;      % study time
            is.cur_sed = is.cur_sd;                    % series date
            is.cur_set = cur_dcm.SeriesTime;           % series time
            
            % fmri params
            is.cur_tr = num2str(cur_dcm.RepetitionTime);  % repetition time
            is.cur_et = num2str(cur_dcm.EchoTime);        % echo time
            is.cur_st = num2str(cur_dcm.SliceThickness);  % slice thickness
            is.cur_ss = num2str(5);                       % slice spacing hard coded from viewing (voxel size z: 5mm)
            is.cur_sx = num2str(cur_dcm.PixelSpacing(1)); % voxel size x
            is.cur_sy = num2str(cur_dcm.PixelSpacing(2)); % voxel size y
            is.cur_nv = num2str(135);                     % number of volumes (hard coded from inventory)
            is.cur_ns = num2str(ref_nifti.dim(3));        % number of slices
            is.cur_ms = 'Interleaved';                    % multi-slice mode
            is.cur_ao = 'Ascending';                      % acquisition order
            
        elseif strcmp(tasks{tt},'fMRI_NBack')
            % here there seems to be always an info text there
            % so we are not writing anything
            
        elseif strcmp(tasks{tt},'fMRI_VR')
            % fMRI params
            is.cur_tr = num2str(1900);          % repetition time
            is.cur_et = num2str(30);            % echo time
            is.cur_st = num2str(2.8);           % slice thickness
            is.cur_ss = num2str(119/34);        % slice spacing
            is.cur_sx = num2str(200/64);        % voxel size x
            is.cur_sy = num2str(200/64);        % voxel size y
            is.cur_nv = num2str(940);           % number of volumes
            is.cur_ns = num2str(34);            % number of slices
            is.cur_ms = 'Interleaved';          % multi-slice mode
            is.cur_ao = 'Ascending';            % acquisition order
            is.cur_sen = 'VR_ep2d';             % series description
        end
        
        % writing
        disp('Writing an fmri params file.')
        agk_write_fmri_info_subf(is)
    end
    disp(['Done checking/writing text files for: ', tasks{tt}])
end

rmpath(cur_p);
