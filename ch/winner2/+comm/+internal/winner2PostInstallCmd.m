function winner2PostInstallCmd
%WINNER2POSTINSTALLCMD displays post installation dialog

% Copyright 2016 The MathWorks, Inc.

registerrealtimecataloglocation(winner2.internal.resourceRoot);

dialogMessage = getString(message('winner2:winner2PostInstallCmd:DialogMessage'));
dialog = msgbox(dialogMessage, 'modal');
uiwait(dialog);

help winner2;

end