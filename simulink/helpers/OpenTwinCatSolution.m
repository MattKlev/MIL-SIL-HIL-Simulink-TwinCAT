function dte = OpenTwinCatSolution(solution)
% OPENTWINCATSOLUTION opens a TwinCAT solution of this repository in TwinCAT XAE.
%
%   dte = OpenTwinCatSolution('sil/TwinCAT SIL.sln')
%
% The path is relative to the twincat folder. Each call starts a new XAE
% instance and returns its DTE object for PlaceWindow and ShowBlockDiagram.
% XAE stays open after MATLAB releases it, so the project can be activated
% from there.

solutionPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'twincat',solution);
if ~isfile(solutionPath)
    error('Solution not found: %s',solutionPath);
end

dte = actxserver('TcXaeShell.DTE.17.0');
dte.set('UserControl',true);
dte.MainWindow.set('Visible',true);
invoke(dte.Solution,'Open',solutionPath);

end
