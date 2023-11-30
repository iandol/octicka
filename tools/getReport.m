% Get a try catch report
function getReport (ME)
	if ~isstruct(ME); return; end
	fprintf('\n\nError Report:\n')
	fprintf('Message: %s\n', ME.message)
	for i = 1:length(ME.stack)
		fprintf('%i -- Pos: %i:%i Name: %s File: %s\n',i,...
		ME.stack(i).line,ME.stack(i).column,ME.stack(i).name,...
		ME.stack(i).file);
	end
end
