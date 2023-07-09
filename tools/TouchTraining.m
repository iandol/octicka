## -*- texinfo -*-
## @deftypefn  {} {@var{wnd} =} TouchTraining ()
##
## Create and show the dialog, return a struct as representation of dialog.
##
## @end deftypefn
function wnd = TouchTraining(varargin)
  TouchTraining_def;
  wnd = show_TouchTraining(varargin{:});
end
