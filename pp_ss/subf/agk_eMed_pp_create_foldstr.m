function agk_eMed_pp_create_foldstr(cur_struct,base_dir_pl)
cd(base_dir_pl)
cur_subf = fullfile(pwd,cur_struct.id);

% make main subf
mkdir(cur_subf)

% make the taks subfolders
all_fields = fieldnames(cur_struct);
for ff = 1:length(all_fields)
    C     = all_fields(ff);
    TEST  = {'id','log','site'};
    out   = cellfun(@(s)find(~cellfun('isempty',strfind(C,s))),TEST,'uni',0);
    do_it = ~any(~cellfun(@isempty,out));
    
    if do_it
       mkdir(fullfile(cur_subf,all_fields{ff})) 
       mkdir(fullfile(cur_subf,all_fields{ff},'niftis'))
       mkdir(fullfile(cur_subf,all_fields{ff},'logfiles'))
       mkdir(fullfile(cur_subf,all_fields{ff},'results'))
    end
    disp('DONE CREATING FOLDER STRUCTURE')
end

cd(base_dir_pl)
return