function PlaceWindow(target, tile)
% PLACEWINDOW moves a window to a tile of the primary screen.
%
%   PlaceWindow('MATLAB','left')        MATLAB desktop
%   PlaceWindow('TempCtrl','topright')  open Simulink model
%   PlaceWindow(dte,'right')            TwinCAT XAE instance returned by OpenTwinCatSolution
%
% tile is one of 'full', 'left', 'right', 'top', 'bottom', 'topleft',
% 'topright', 'bottomleft', 'bottomright', or [x y w h] as fractions of the
% work area (the screen without the taskbar), e.g. [0 0 0.5 1] for 'left'.
%
% XAE is placed through the Automation Interface, Simulink through the model
% Location parameter, and the MATLAB desktop through Windows UI Automation.

arguments
    target
    tile
end
import System.Windows.Automation.*

% target rectangle in pixels
NET.addAssembly('System.Windows.Forms');
work = System.Windows.Forms.Screen.PrimaryScreen.WorkingArea;
work = double([work.X work.Y work.Width work.Height]);
if ischar(tile) || isstring(tile)
    tiles = struct( ...
        'full',[0 0 1 1], 'left',[0 0 .5 1], 'right',[.5 0 .5 1], ...
        'top',[0 0 1 .5], 'bottom',[0 .5 1 .5], ...
        'topleft',[0 0 .5 .5], 'topright',[.5 0 .5 .5], ...
        'bottomleft',[0 .5 .5 .5], 'bottomright',[.5 .5 .5 .5]);
    tile = tiles.(lower(char(tile)));
end
x = round(work(1) + tile(1)*work(3));
y = round(work(2) + tile(2)*work(4));
w = round(tile(3)*work(3));
h = round(tile(4)*work(4));

if startsWith(class(target),'COM.')
    % TwinCAT XAE (EnvDTE.DTE): vsWindowStateNormal = 0
    mw = target.MainWindow;
    set(mw,'WindowState',0);
    set(mw,'Left',x); set(mw,'Top',y); set(mw,'Width',w); set(mw,'Height',h);
elseif strcmpi(target,'MATLAB')
    % MATLAB desktop runs in its own process, find its window by title
    % (retry briefly, the enumeration can miss it while other windows close)
    NET.addAssembly('UIAutomationClient'); NET.addAssembly('UIAutomationTypes');
    t = tic;
    while true
        windows = AutomationElement.RootElement.FindAll(TreeScope.Children, Condition.TrueCondition);
        for i = 0:windows.Count-1
            win = windows.Item(i);
            if startsWith(char(win.Current.Name), ['MATLAB R' version('-release')])
                win.GetCurrentPattern(WindowPattern.Pattern).SetWindowVisualState(WindowVisualState.Normal);
                transform = win.GetCurrentPattern(TransformPattern.Pattern);
                transform.Move(x,y);
                transform.Resize(w,h);
                return
            end
        end
        if toc(t) > 3
            error('MATLAB desktop window not found.');
        end
        pause(0.25);
    end
elseif bdIsLoaded(target)
    % Simulink model window: [left top right bottom]
    set_param(target,'Location',[x y x+w y+h]);
else
    error('Unknown window: %s',target);
end

end
