function ShowBlockDiagram(dte, objectName)
% SHOWBLOCKDIAGRAM opens a TcCOM object in TwinCAT XAE and shows its Block Diagram tab.
%
%   dte = OpenTwinCatSolution('sil/TwinCAT SIL.sln');
%   ShowBlockDiagram(dte,'TempCtrl')
%
% The Automation Interface has no call to open the editor of a tree item, so
% the item is selected in the Solution Explorer through Windows UI Automation,
% opened with the default action of the Solution Explorer (a double-click),
% and the Block Diagram tab of the editor is selected the same way.

arguments
    dte
    objectName (1,1) string
end

NET.addAssembly('UIAutomationClient'); NET.addAssembly('UIAutomationTypes');
import System.Windows.Automation.*

% Solution Explorer: vsWindowKindSolutionExplorer
explorer = invoke(dte.Windows,'Item','{3AE79031-E1BC-11D0-8F78-00A0C9110057}');
hierarchy = get(explorer,'Object');

% expand the tree down to the TcCOM objects so the item exists in the UI
solutionName = get(invoke(get(hierarchy,'UIHierarchyItems'),'Item',1),'Name');
projectName = get(invoke(dte.Solution.Projects,'Item',1),'Name');
path = solutionName;
for node = [string(projectName) "SYSTEM" "TcCOM Objects"]
    path = path + "\" + node;
    set(get(invoke(hierarchy,'GetItem',char(path)),'UIHierarchyItems'),'Expanded',true);
end
item = invoke(hierarchy,'GetItem',char(path + "\" + objectName));

% select the item in the tree and open its editor
xaeWindow = AutomationElement.FromHandle(System.IntPtr(get(dte.MainWindow,'HWnd')));
treeItem = findElement(xaeWindow, ControlType.TreeItem, objectName, 5);
treeItem.GetCurrentPattern(ScrollItemPattern.Pattern).ScrollIntoView();
treeItem.GetCurrentPattern(SelectionItemPattern.Pattern).Select();
if ~get(item,'IsSelected')
    error('Could not select %s in the Solution Explorer.',objectName);
end
invoke(hierarchy,'DoDefaultAction');

% switch the editor to the Block Diagram tab
tab = findElement(xaeWindow, ControlType.TabItem, "Block Diagram", 10);
tab.GetCurrentPattern(SelectionItemPattern.Pattern).Select();
invoke(dte.MainWindow,'Activate');

end

function element = findElement(root, controlType, name, timeout)
% first descendant of root with the given control type and name, waits up to timeout seconds
import System.Windows.Automation.*
t = tic;
while true
    candidates = root.FindAll(TreeScope.Descendants, PropertyCondition(AutomationElement.NameProperty, char(name)));
    for i = 0:candidates.Count-1
        element = candidates.Item(i);
        if element.Current.ControlType.Id == controlType.Id
            return
        end
    end
    if toc(t) > timeout
        error('"%s" not found in the TwinCAT XAE window.',name);
    end
    pause(0.25);
end
end
