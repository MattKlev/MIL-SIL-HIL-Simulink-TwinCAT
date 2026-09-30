function UpdateTwinCatProjects(projExporter)
% UPDATETWINCATPROJECTS reloads the TcCOM objects of the TwinCAT projects in
% this repository with the module version that was just built.
%
% Post publish callback of the models TempCtrl and TempCtrlSysPT2 (TC Build,
% parameter TcProject_PostPublishCallbackFcn). It uses the TwinCAT Automation
% Interface, so close the projects in TwinCAT XAE before building.

libName = char(projExporter.Project.TMC.LibName);

% TcCOM objects that instantiate the module: solution, tree item
twinCatDir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'twincat');
switch libName
    case 'TempCtrl'
        targets = { ...
            fullfile(twinCatDir,'sil','TwinCAT SIL.sln'),                      'TIRC^TcCOM Objects^TempCtrl'; ...
            fullfile(twinCatDir,'hil-master','TwinCAT Project EC Master.sln'), 'TIRC^TcCOM Objects^TempCtrl'};
    case 'TempCtrlSysPT2'
        targets = { ...
            fullfile(twinCatDir,'hil-sim','TwinCAT Project EC Sim.sln'),       'TIRC^TcCOM Objects^TempCtrlSysPT2'};
    otherwise
        return
end

% path of the tmc file in the engineering repository
try
    repoDir = winqueryreg('HKEY_LOCAL_MACHINE','Software\Wow6432Node\Beckhoff\TwinCAT3\3.1','RepositoryDir');
catch
    repoDir = fullfile(getenv('TwinCAT3Dir'),'Repository');
end
libVersion = char(projExporter.Project.TMC.LibVersion);
tmcPath = fullfile(repoDir,char(projExporter.Project.TMC.Vendor.Name),libName,libVersion,[libName '.tmc']);
reloadXml = ['<TreeItem><ReloadTmc Path="' tmcPath '"></ReloadTmc></TreeItem>'];

% message filter to handle busy XAE instances
NET.addAssembly(fullfile(char(TwinCAT.ModuleGenerator.ProductInfo.InstallPath),'NET','TwinCAT.ModuleGenerator.HelperLib.dll'));
if ~TwinCAT.ModuleGenerator.HelperLib.MessageFilter.IsRegistered
    TwinCAT.ModuleGenerator.HelperLib.MessageFilter.Register();
end

% start TwinCAT XAE without user interface
dte = actxserver('TcXaeShell.DTE.17.0');
closeXae = onCleanup(@() dte.Quit());
dte.MainWindow.set('Visible',false);
dte.set('SuppressUI',true);

for i = 1:size(targets,1)
    solution = dte.Solution;
    invoke(solution,'Open',targets{i,1});
    project = solution.Projects.Item(1);
    sysManager = project.get('Object');

    tcCom = sysManager.LookupTreeItem(targets{i,2});
    tcCom.ConsumeXml(reloadXml);

    project.Save();
    solution.SaveAs(solution.FullName);
    solution.Close();
    fprintf('### Reloaded %s %s in %s\n',libName,libVersion,targets{i,1});
end

end
