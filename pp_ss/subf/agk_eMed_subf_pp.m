function agk_eMed_subf_pp(cur_struct,base_dir_pl,des_tasks,tasks,des_sites,sites,do_run_pp,allow_skip_pp,ow_pp,allow_cut,ow_pp_t1)
% function that does the actual preprocessing
% try
cd(base_dir_pl)
cur_subf = fullfile(pwd,cur_struct.id);

% check cutting and overwriting
if ow_pp == 0
    assert(ow_pp_t1 == 0)
end
if ow_pp_t1
    assert(allow_cut == 0 && ow_pp == 1)
end

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
error_msg       = {};
for ff = 1:length(all_fields)
    % fields that are not for preprocessing
    C         = cellstr(all_fields(ff));
    TEST      = {'id','log','site','t1'};
    out       = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_out = ~any(~cellfun(@isempty,out));
    
    % test if from a desired task
    C        = cellstr(all_fields(ff));
    TEST     = tasks(des_tasks);
    out      = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it_in = any(~cellfun(@isempty,out));
    
    if do_it_in && do_it_out
        % this is a desired task series
        % check dcms
        cur_dcm = getfield(cur_struct,all_fields{ff});
        if isempty(cur_dcm)
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... had no dicoms, so cannot have niftis!'];
            disp(error_msg{ff,1})
            continue
        end
        
        % check if logfile is there
        if isempty(getfield(cur_struct,[all_fields{ff} '_log']))
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no logfiles! I will skip for now.'];
            disp(error_msg{ff,1})
            continue
        end
        
        % use the dcmHeader info
        cur_src_dir = fullfile(base_dir_pl,cur_struct.id,all_fields{ff},'niftis');
        
        if ~exist(cur_src_dir)
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} 'directory does not exist. Copy it back! Skipping.'];
            disp(error_msg{ff,1})
            continue
        end
        
        cd(cur_src_dir)
        if exist('dcmHeaders.mat')
            load('dcmHeaders.mat')
        else
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no dcmHeaders! I will skip for now.'];
            disp(error_msg{ff,1})
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
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no slice timing info in dcmHeaders! I will skip for now.'];
            disp(error_msg{ff,1})
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
            error_msg{ff,2} =  ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no valid SliceTimes; nslices: ' num2str(length(sliceTiming))];
            disp(error_msg{ff,2})
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
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no niftis!'];
            disp(error_msg{ff,1})
            continue
        end
        st_scans = fullfile(cur_src_dir,st_scans);
        
        %             % get the voxel size
        %             cur_vol = spm_vol(st_scans{1});
        %             cur_inf = spm_imatrix(cur_vol.mat);
        %             cur_vs  = abs(cur_inf(7:9));
        
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
                error_msg{ff,2} =  ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has mismatch slice order situation!'];
                disp(error_msg{ff,2})
                continue
            end
        else
            % no valid SliceTiming: so we trust the slice order
            % complete later
        end
        
        if ow_pp == 0
            % check if already preprocessed
            pp_files = cellstr(ls('swra*.nii'));
            if length(pp_files) == length(st_scans)
                error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has already been preprocessed!'];
                disp(error_msg{ff,1})
                continue
            end
        end
        
        % check if we can skip slice timing and realignment
        if allow_skip_pp
            cur_ra_epis = cellstr(ls('ra*.nii'));
            if length(cur_ra_epis) == length(st_scans)
                warning('slice timing and realignment happened already. skipping')
                skip = 'realign';
            else
                skip = '';
            end
        else
            skip = '';
        end
        
        % get the t1 image
        cur_t1_dir = fullfile(base_dir_pl,cur_struct.id,'t1','niftis');
        cd(cur_t1_dir)
        cur_t1     = cellstr(ls('t1_mpr*.nii'));
        
        % total overwrite pp: delete all previous t1 pp
        if ow_pp_t1
            all_files_in_t1 = cellstr(ls());
            all_files_in_t1 = all_files_in_t1(3:end);
            ind  = find(~cellfun(@isempty,regexp(all_files_in_t1,'^t1.*')));
            ind  = ind(:);
            ind2 = find(~cellfun(@isempty,regexp(all_files_in_t1,'^dcmHeaders.*')));
            ind2 = ind2(:);
            ind  = [ind;ind2];
            
            all_files_in_t1(ind) = [];
            
            for xx = 1:length(all_files_in_t1)
                delete(all_files_in_t1{xx});
            end
        end
        
        if length(cur_t1) > 1
            error_msg{ff,2} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has mult t1, taking first one!'];
            warning(error_msg{ff,2});
        end
        
        if isempty(cur_t1{1})
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no t1! Need to skip them!'];
            disp(error_msg{ff,1})
            return
        end
        
        % note down
        t1 = cur_t1{1};
        t1 = fullfile(cur_t1_dir,t1);
        
        % fill and run the batch
        warning(['The subject ' cur_struct.id ' series ' all_fields{ff} '... is starting now!']);
        matlabbatch = fun_fill_batch(st_scans,nslices,tr,ta,so,refslice,t1,skip,all_fields{ff},allow_cut);
        if isempty(matlabbatch)
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} 'has empty matlabbatch; probably need to run ALCUE pp first.'];
            disp(error_msg{ff,1})
            continue
        end
        
        % run it
        cd(cur_src_dir)
        if do_run_pp
            spm_jobman('run',matlabbatch);
            % leave a note that it is done
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been preprocessed sucessfully!'];
            cd(cur_src_dir)
            save('success.mat','error_msg')
            disp(error_msg{ff,1})
        else
            error_msg{ff,1} = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has only had batch created. Not run!'];
            disp(error_msg{ff,1})
        end
    end
end
return
% catch error_msg
%     warning(error_msg.message)
%     cd(base_dir_pl)
%     return
% end

    function matlabbatch = fun_fill_batch(st_scans,nslices,tr,ta,so,refslice,t1,skip,cur_task,allow_cut)
        
        % get the folders
        [p f e] = fileparts(st_scans{1});
        cd(p)
        % mean epi for coregistering t1
        % get the nifti name
        cur_h = load('dcmHeaders.mat');
        cur_allfields = fieldnames(cur_h.h);
        cur_epis = cellstr(ls([cur_allfields{1} '*.nii']));
        epi_mean = cellstr(fullfile(pwd,['meana' cur_epis{1}]));
        % realigned epis
        ra_epis  = strcat('ra',cur_epis);
        a_epis   = strcat('a',cur_epis);
        % forward deformations
        % get t1
        [pt1 ft1 et1] = fileparts(t1);
        
        % fills the matlabbatch and returns it
        % slice timing
        matlabbatch{1}.spm.temporal.st.scans = {st_scans};
        matlabbatch{1}.spm.temporal.st.nslices = nslices;
        matlabbatch{1}.spm.temporal.st.tr = tr;
        matlabbatch{1}.spm.temporal.st.ta = ta;
        matlabbatch{1}.spm.temporal.st.so = so;             % time in ms or slice ind
        matlabbatch{1}.spm.temporal.st.refslice = refslice; % time in ms or slice ind
        matlabbatch{1}.spm.temporal.st.prefix = 'a';
        % rigid realignment of all epis to mean epi
        matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 2;
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = '';
        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [2 1];
        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 4;
        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask = 1;
        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
        % coregister t1 on mean epi
        matlabbatch{3}.spm.spatial.coreg.estimate.ref    = epi_mean;
        matlabbatch{3}.spm.spatial.coreg.estimate.source = {fullfile(pt1,[ft1 et1])};
        matlabbatch{3}.spm.spatial.coreg.estimate.other  = {''};
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];      
%         matlabbatch{3}.spm.spatial.coreg.estwrite.ref = {fullfile(pt1,[ft1 et1])}; % exchanging source and reference; due to reslicing; so that t1 stays high res
%         matlabbatch{3}.spm.spatial.coreg.estwrite.source = epi_mean;
%         matlabbatch{3}.spm.spatial.coreg.estwrite.other = ra_epis;
%         matlabbatch{3}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
%         matlabbatch{3}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
%         matlabbatch{3}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
%         matlabbatch{3}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
%         matlabbatch{3}.spm.spatial.coreg.estwrite.roptions.interp = 4;
%         matlabbatch{3}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
%         matlabbatch{3}.spm.spatial.coreg.estwrite.roptions.mask = 0;
%         matlabbatch{3}.spm.spatial.coreg.estwrite.roptions.prefix = 'r'; % r prefix, it's now 'rr...' for the epis      
%         rra_epis = strcat('rra',cur_epis);
        % segment and normalise the t1; estimate normalisation field
        matlabbatch{4}.spm.spatial.preproc.channel.vols = {fullfile(pt1,[ft1 et1])};
        matlabbatch{4}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{4}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{4}.spm.spatial.preproc.channel.write = [0 1];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,1'};
        matlabbatch{4}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{4}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).warped = [1 1];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,2'};
        matlabbatch{4}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{4}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).warped = [1 1];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,3'};
        matlabbatch{4}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,4'};
        matlabbatch{4}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{4}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,5'};
        matlabbatch{4}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{4}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).tpm = {'C:\Program Files\spm12\tpm\TPM.nii,6'};
        matlabbatch{4}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{4}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{4}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{4}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{4}.spm.spatial.preproc.warp.write = [0 1];
        % apply normalization on realigned epis
        matlabbatch{5}.spm.spatial.normalise.write.subj.def(1) = {fullfile(pt1, ['y_' ft1 et1])};
        matlabbatch{5}.spm.spatial.normalise.write.subj.resample = [];
        matlabbatch{5}.spm.spatial.normalise.write.subj.resample = ra_epis;
        matlabbatch{5}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
            78 76 85];
        matlabbatch{5}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
        matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = 'w';
        % smooth the normalized epis
        matlabbatch{6}.spm.spatial.smooth.data = fullfile(p,strcat('w',ra_epis));
        matlabbatch{6}.spm.spatial.smooth.fwhm = [8 8 8];
        matlabbatch{6}.spm.spatial.smooth.dtype = 0;
        matlabbatch{6}.spm.spatial.smooth.im = 0;
        matlabbatch{6}.spm.spatial.smooth.prefix = 's';
        % apply the normalization to realigned t1
        matlabbatch{7}.spm.spatial.normalise.write.subj.def(1) = {fullfile(pt1, ['y_' ft1 et1])};
        matlabbatch{7}.spm.spatial.normalise.write.subj.resample(1) = {fullfile(pt1, [ft1 et1])};
        matlabbatch{7}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
            78 76 85];
        matlabbatch{7}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{7}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{7}.spm.spatial.normalise.write.woptions.prefix = 'w';
        % smooth the t1 segmentations
        matlabbatch{8}.spm.spatial.smooth.data(1) = {fullfile(pt1, ['wc1' ft1 et1])};
        matlabbatch{8}.spm.spatial.smooth.fwhm = [8 8 8];
        matlabbatch{8}.spm.spatial.smooth.dtype = 0;
        matlabbatch{8}.spm.spatial.smooth.im = 0;
        matlabbatch{8}.spm.spatial.smooth.prefix = 's';
        matlabbatch{9}.spm.spatial.smooth.data(1) = {fullfile(pt1, ['wc2' ft1 et1])};
        matlabbatch{9}.spm.spatial.smooth.fwhm = [8 8 8];
        matlabbatch{9}.spm.spatial.smooth.dtype = 0;
        matlabbatch{9}.spm.spatial.smooth.im = 0;
        matlabbatch{9}.spm.spatial.smooth.prefix = 's';
        matlabbatch{10}.spm.spatial.smooth.data(1) = {fullfile(pt1, ['mwc1' ft1 et1])};
        matlabbatch{10}.spm.spatial.smooth.fwhm = [8 8 8];
        matlabbatch{10}.spm.spatial.smooth.dtype = 0;
        matlabbatch{10}.spm.spatial.smooth.im = 0;
        matlabbatch{10}.spm.spatial.smooth.prefix = 's';
        matlabbatch{11}.spm.spatial.smooth.data(1) = {fullfile(pt1, ['mwc2' ft1 et1])};
        matlabbatch{11}.spm.spatial.smooth.fwhm = [8 8 8];
        matlabbatch{11}.spm.spatial.smooth.dtype = 0;
        matlabbatch{11}.spm.spatial.smooth.im = 0;
        matlabbatch{11}.spm.spatial.smooth.prefix = 's';
        
        % skipping something and everything before
        to_cut = [];
        if strcmp(skip,'realign')
            % dropping pp steps
            to_cut = [to_cut 1 2];
        end
        
        if allow_cut
            % cut segmentation if already done
            % check if t1 has already been segmented
            [pt1,ft1,et1] = fileparts(t1);
            cd(pt1)
            if exist(fullfile(pt1, ['y_' ft1 et1]))
                to_cut = [to_cut 4];
            end
            
            % check if the smoothing of t1 segements have been written (smooth)
            test_1 = exist(fullfile(pt1, ['swc1t1' ft1 et1]));
            test_2 = exist(fullfile(pt1, ['smwc1t1' ft1 et1]));
            test_3 = exist(fullfile(pt1, ['swc2t1' ft1 et1]));
            test_4 = exist(fullfile(pt1, ['smwc2t1' ft1 et1]));
            
            if test_1 && test_2 && test_3 && test_4
                to_cut = [to_cut 8:11];
            end
            
            % check if normalized t1 is there
            test_1 = exist(fullfile(pt1, ['w' ft1 et1]));
            
            if test_1
                to_cut = [to_cut 7];
            end
        end
        
        if ~exist(fullfile(pt1, ['y_' ft1 et1])) && ~strcmp(cur_task,'ALCUE')
            warning('No pp t1 and this is not ALCUE. First pp with ALCUE!')
            matlabbatch = [];
            return
        end
        
        % change the coregistration logic
        if exist(fullfile(pt1, ['y_' ft1 et1])) && ~strcmp(cur_task,'ALCUE')           
            matlabbatch{3}.spm.spatial.coreg.estimate.ref = {fullfile(pt1, [ft1 et1])};
            matlabbatch{3}.spm.spatial.coreg.estimate.source = epi_mean;
            matlabbatch{3}.spm.spatial.coreg.estimate.other = a_epis;
        end
        
        % CUTTING THE MATLABBATCH
        % the cut is only useful if already one ss model (ALCUE) has
        % successfully been pp'd including t1
        matlabbatch(to_cut) = [];
        
        % SAVING
        cd(p)
        save(['preprocess_batch_' date '.mat'],'matlabbatch')  
    end
end