function pid = streamer
	i = mfilename ("fullpathext");
	[p,f,e] = fileparts(i);
	cmd = [p filesep "streamer.sh"];
	fprintf('Running: %s\n',cmd);
	pid=system([p filesep "streamer.sh"],false,"async");
end
