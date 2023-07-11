function pid = rpistreamer
	pid = [];
	try
		e = system('which libcamera-vid');
		if e > 0; warning('Cannot find libcamera-vid!!!');return;end
		i = mfilename ("fullpathext");
		[p,f,e] = fileparts(i);
		cmd = [p filesep "streamer.sh"];
		fprintf('Running: %s\n',cmd);
		pid=system([p filesep "streamer.sh"],false,"async");
	end
end
