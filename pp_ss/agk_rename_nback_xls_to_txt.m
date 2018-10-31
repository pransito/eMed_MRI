% script to rename nback.xls to nback.txt

rootPath = 'G:\NGFN\fMRI_NBack\NBack_Logfiles';
cd(rootPath)
allSites = cellstr(ls());

for ss = 3:length(allSites)
    cd(allSites{ss})
    % get the xls files
    xlsFiles = cellstr(ls('*.xls'));
    for ff = 1:length(xlsFiles)
        % rename and copy
        oldName = xlsFiles{ff};
        splName = strsplit(oldName,'.');
        newName = [splName{1} '_nbacklog.txt'];
        copyfile(oldName,newName);
        disp('done copying')
    end
    cd(rootPath)
end

