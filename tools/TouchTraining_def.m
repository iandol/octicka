## -*- texinfo -*-
## @deftypefn  {} {} dummy()
##
## This is a dummy function documentation. This file have a lot functions
## and each one have a little documentation. This text is to avoid a warning when
## install this file as part of package.
## @end deftypefn
##
## Set the graphics toolkit and force read this file as script file (not a function file).
##
graphics_toolkit qt;
##


##
##
## Begin callbacks definitions
##

## @deftypefn  {} {} TouchTraining_StartButton_doIt (@var{src}, @var{data}, @var{TouchTraining})
##
## Define a callback for default action of StartButton control.
##
## @end deftypefn
function TouchTraining_StartButton_doIt(src, data, TouchTraining)

% This code will be executed when user click the button control.
% As default, all events are deactivated, to activate must set the
% property 'generateCallback' from the properties editor

tr.name = get(TouchTraining.SubjectName,'String');
tr.phase = str2num(get(TouchTraining.Phase,'String'));
tr.bg = str2num(get(TouchTraining.BackgroundColour,'String'));
tr.fg = str2num(get(TouchTraining.TouchColour,'String'));
tr.stream = logical(get(TouchTraining.StreamVideo,'Value'));
tr.debug = logical(get(TouchTraining.Debug,'Value'));

startTraining(tr)
end

## @deftypefn  {} {} TouchTraining_Load_doIt (@var{src}, @var{data}, @var{TouchTraining})
##
## Define a callback for default action of Load control.
##
## @end deftypefn
function TouchTraining_Load_doIt(src, data, TouchTraining)

% This code will be executed when user click the button control.
% As default, all events are deactivated, to activate must set the
% property 'generateCallback' from the properties editor

[f,p] = uigetfile('*.mat');
if isnumeric(f); return; end
oldp = pwd;
cd(p);
load(f);
cd(pwd);
if exist('d','var') && ~isempty(d) && isfield(d,'data')
	try
		set(TouchTraining.SubjectName,'String',d.subject)
		if ~isempty(d.data.result)
			set(TouchTraining.Phase,'String',num2str(max(d.data.phase)))
			x = d.data.time - d.data.time(1);
			n = length(d.data.phase);
			figure;
			subplot(3,1,1);
			plot(x,d.data.phase);
			title(d.name);
			ylabel('Phase');
			xlabel('Time (s)')
			subplot(3,1,2)
			plot(x,d.data.result);
			ylim([-0.1 1.1])
			ylabel('Correct/Incorrect');
			xlabel('Time (s)')
			subplot(3,1,3)
			plot(x,d.data.rt);
			ylabel('Reaction Time (s)');
			xlabel('Time (s)')
		end
	end

end

end


## @deftypefn  {} {@var{ret} = } show_TouchTraining(varargin)
##
## Create windows controls over a figure, link controls with callbacks and return
## a window struct representation.
##
## @end deftypefn
function ret = show_TouchTraining(varargin)
  _scrSize = get(0, "screensize");
  _xPos = (_scrSize(3) - 915)/2;
  _yPos = (_scrSize(4) - 591)/2;
   TouchTraining = figure ( ...
	'Color', [0.937 0.937 0.937], ...
	'Position', [_xPos _yPos 915 591], ...
	'resize', 'off', ...
	'windowstyle', 'normal', ...
	'MenuBar', 'none');
	 set(TouchTraining, 'visible', 'off');
  Settings = uibuttongroup( ...
	'parent',TouchTraining, ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'BorderWidth', 1, ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'bold', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'Position', [0 5 907 581], ...
	'title', 'Touch Training Settings', ...
	'TitlePosition', 'righttop', ...
	'visible', 'on');
  StartButton = uicontrol( ...
	'parent',Settings, ...
	'Style','pushbutton', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'bold', ...
	'ForegroundColor', [0.643 0.000 0.000], ...
	'Position', [710 9 190 59], ...
	'String', 'Start!', ...
	'TooltipString', '', ...
	'visible', 'on');
  SubjectName = uicontrol( ...
	'parent',Settings, ...
	'Style','edit', ...
	'Units', 'pixels', ...
	'BackgroundColor', [1.000 1.000 1.000], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'center', ...
	'Position', [35 479 294 47], ...
	'String', 'Test', ...
	'TooltipString', '', ...
	'visible', 'on');
  Phase = uicontrol( ...
	'parent',Settings, ...
	'Style','edit', ...
	'Units', 'pixels', ...
	'BackgroundColor', [1.000 1.000 1.000], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'center', ...
	'Position', [35 414 294 47], ...
	'String', '1', ...
	'TooltipString', '', ...
	'visible', 'on');
  BackgroundColour = uicontrol( ...
	'parent',Settings, ...
	'Style','edit', ...
	'Units', 'pixels', ...
	'BackgroundColor', [1.000 1.000 1.000], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'center', ...
	'Position', [35 349 294 47], ...
	'String', '[0.2 0.2 0.2]', ...
	'TooltipString', '', ...
	'visible', 'on');
  TouchColour = uicontrol( ...
	'parent',Settings, ...
	'Style','edit', ...
	'Units', 'pixels', ...
	'BackgroundColor', [1.000 1.000 1.000], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'center', ...
	'Position', [35 284 294 47], ...
	'String', '[1 1 1]', ...
	'TooltipString', '', ...
	'visible', 'on');
  Label_1 = uicontrol( ...
	'parent',Settings, ...
	'Style','text', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'left', ...
	'Position', [335 482 157 39], ...
	'String', 'Subject Name', ...
	'TooltipString', '', ...
	'visible', 'on');
  Label_2 = uicontrol( ...
	'parent',Settings, ...
	'Style','text', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'left', ...
	'Position', [335 417 166 39], ...
	'String', 'Training Phase', ...
	'TooltipString', '', ...
	'visible', 'on');
  Label_3 = uicontrol( ...
	'parent',Settings, ...
	'Style','text', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'left', ...
	'Position', [335 352 218 39], ...
	'String', 'Background Colour', ...
	'TooltipString', '', ...
	'visible', 'on');
  Label_4 = uicontrol( ...
	'parent',Settings, ...
	'Style','text', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'HorizontalAlignment', 'left', ...
	'Position', [335 287 150 39], ...
	'String', 'Touch Colour', ...
	'TooltipString', '', ...
	'visible', 'on');
  StreamVideo = uicontrol( ...
	'parent',Settings, ...
	'Style','checkbox', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'Position', [300 221 279 45], ...
	'String', 'Stream Video', ...
	'TooltipString', '', ...
	'Min', 0, 'Max', 1, 'Value', 1, ...
	'visible', 'on');
  Debug = uicontrol( ...
	'parent',Settings, ...
	'Style','checkbox', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'Position', [300 161 184 45], ...
	'String', 'Debug', ...
	'TooltipString', '', ...
	'Min', 0, 'Max', 1, 'Value', 0, ...
	'visible', 'on');
  Load = uicontrol( ...
	'parent',Settings, ...
	'Style','pushbutton', ...
	'Units', 'pixels', ...
	'BackgroundColor', [0.937 0.937 0.937], ...
	'FontAngle', 'normal', ...
	'FontName', 'Source Sans 3', ...
	'FontSize', 10, 'FontUnits', 'points', ...
	'FontWeight', 'normal', ...
	'ForegroundColor', [0.000 0.000 0.000], ...
	'Position', [10 10 180 56], ...
	'String', 'Load', ...
	'TooltipString', '', ...
	'visible', 'on');

  TouchTraining = struct( ...
      'figure', TouchTraining, ...
      'Settings', Settings, ...
      'StartButton', StartButton, ...
      'SubjectName', SubjectName, ...
      'Phase', Phase, ...
      'BackgroundColour', BackgroundColour, ...
      'TouchColour', TouchColour, ...
      'Label_1', Label_1, ...
      'Label_2', Label_2, ...
      'Label_3', Label_3, ...
      'Label_4', Label_4, ...
      'StreamVideo', StreamVideo, ...
      'Debug', Debug, ...
      'Load', Load);


  set (StartButton, 'callback', {@TouchTraining_StartButton_doIt, TouchTraining});
  set (Load, 'callback', {@TouchTraining_Load_doIt, TouchTraining});
  dlg = struct(TouchTraining);

  set(TouchTraining.figure, 'visible', 'on');

%
% The source code written here will be executed when
% windows load. Works like 'onLoad' event of other languages.
%



  ret = TouchTraining;
end

