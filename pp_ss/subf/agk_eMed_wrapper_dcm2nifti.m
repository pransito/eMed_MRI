function error_msg = agk_eMed_wrapper_dcm2nifti(cur_struct,base_dir_pl)
try
    cd(base_dir_pl)
    cur_subf = fullfile(pwd,cur_struct.id);
    
    % make the taks subfolders
    all_fields = fieldnames(cur_struct);
    for ff = 1:length(all_fields)
        C     = all_fields(ff);
        TEST  = {'id','log','site'};
        out   = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
        do_it = ~any(~cellfun(@isempty,out));
        
        if do_it
            % this is a series
            % source
            cur_dcm    = getfield(cur_struct,all_fields{ff});
            if isempty(cur_dcm)
                error_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has no dicoms indicated!'];
                continue
            end
            cur_src    = fileparts(cur_dcm{1});
            % target
            cur_tar    = fullfile(cur_subf,all_fields{ff},'niftis');
            
            % check if already nifits at target
            cd(cur_tar)
            cur_n_tar = cellstr(ls('*.nii'));
            if ~isempty(cur_n_tar{1})
                error_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been already converted!'];
                disp(error_msg)
                continue
            end
            
            % options
            outFormat  = '3D.nii';
            MoCoOption = 0;
           
            % convert
            dicm2nii(cur_src, cur_tar, outFormat,MoCoOption)
            error_msg = ['The subject ' cur_struct.id ' series ' all_fields{ff} '... has been converted sucessfully!'];
            disp(error_msg)
        end
    end
    return
catch error_msg
    warning(error_msg.message)
    cd(base_dir_pl)
    return
end