function playMovies(folder)
	pixelsPerCm = 32;
	timeOut = 2;
	subjectName = '13';
	rewardPort = '/dev/ttyACM0';
	debug = false;
	if debug
		if max(Screen('Screens'))==0; windowed = [0 0 1600 900]; end
		sf = kPsychGUIWindow;
		dummy = true;
		colour1 = [1 0.5 0 0.4];
		colour2 = [0 1 1 0.4];
	else
		windowed = []; sf = [];
		dummy = true;
		colour1 = [1 0.5 0 0.4];
		colour2 = [1 0.5 0 0.4];
	end

	if IsOctave; try pkg load instrument-control; end; end

	% ============================movie / position list
	movieList = {'~/Code/octicka/stimuli/monkey-dance.avi'};
	positionList = {...
		[-20 -14 -13 -3 -20 4 -13 15.2],...
		[-20 4 -13 15.2 -20 -14 -13 -3],...
		[-20 -14 -13 -3 -20 4 -13 15.2],...
		[-19.1 0.6 -12.6 5.1 -19.1 6.4 -12.6 10.8],...
		[-19.6 7.3 -13.1 11.6 -19.1 1.3 -12.4 5.6 ],...
		[-19.6 7.1 -13.1 12.1 -19.6 -1.1 -12.6 3.6]}; % @ 32pxpercm
	%movieList = {'~/Code/octicka/tests/ball.mkv','~/Code/octicka/tests/ball.mkv'};
	%positionList ={[-20 -14 -13 -3 -20 4 -13 15.2],[-20 4 -13 15.2 -20 -14 -13 -3]};
	for i = 1 : length(movieList)
		movieList{i} = regexprep(movieList{i}, '^~\/', [getenv('HOME') filesep]);
	end

	try
		% ============================screen
		s = screenManager('blend',true,'pixelsPerCm',pixelsPerCm,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		rn = 1;
		m = movieStimulus('fileName',movieList{rn},'angle',90,'loopStrategy',0);
		c1 = discStimulus('size',5,'colour',[1 1 1 1]);

		% t============================ouch
		t = touchManager('isDummy',dummy);
		t.window.doNegation = true;
		t.negationBuffer = 2;

		% ============================reward
		rM = arduinoManager('port',rewardPort,'shield','new','verbose',false);
		try open(rM); end

		% ============================setup
		sv = open(s);
		setup(c1, s);
		setup(t, s);
		createQueue(t);
		start(t);

		% ==============================save file name
		svn = initialiseSaveFile(s);
		saveName = [ s.paths.savedData filesep 'IntPhys-' subjectName '-' svn '.mat'];

		% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		Screen('Preference','Verbosity',4);
		try Priority(1); end
		txt = 'Waiting for touch...';
		keepRunning = true
		trialN = 0;
		presentationTime=m.duration;
		responseTime = 2;
		timeOut = 2;
		trials = struct;
		srect = [sv.leftInDegrees+0.1,sv.topInDegrees+0.1,...
			sv.rightInDegrees-0.1,sv.bottomInDegrees-0.1];

		while keepRunning

			% get a new movie from the list
			rn = randi(length(movieList));
			reset(m);
			positions = positionList{rn};
			m.fileName = movieList{rn};
			setup(m, s);
			presentationTime = m.duration;

			%make our touch window around stimulus c1
			t.window.X = c1.xPosition;
			t.window.Y = c1.yPosition;
			t.window.radius = [c1.size / 2, c1.size / 2];
			t.window.doNegation = true;
			x = []; y = []; touched = false; touchedResponse = false;
			trialN = trialN + 1;
			trials(trialN).movieName = m.fileName;
			trials(trialN).targetPosition = positions;
			touchStart = false;
			fprintf('\n===> START TRIAL: %i\n', trialN);
			fprintf('===> Chosen Movie %i = %s\n',rn, m.fileName);


			%=======================================================wait for an initiate touch
			flush(t);
			vbl = flip(s); vblInit = vbl;
			while ~touchStart
				draw(c1);
				if debug && ~isempty(x) && ~isempty(y)
					drawText(s, txt);
					[xy] = s.toPixels([x y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touched, x, y] = checkTouchWindow(t);
				txt = sprintf('Touch = %i x=%.2f y=%.2f',touched,x,y);
				flush(t);
				if touched == 1
					touchStart = true;
				elseif touched == -100;
					drawBackground(s,[1 0 0]);
					if debug; drawText(s,'EXCLUSION!'); end
					flip(s);
					WaitSecs(timeOut);
					drawBackground(s);
					continue;
				end
				[~,~,c] = KbCheck(-1);
				if c(quitKey); keepRunning=false; break; end
			end
			trials(trialN).initTime = vbl - vblInit;
			flip(s);
			WaitSecs(0.5);
			if keepRunning == false; break; end

			%================================================show movie
			vbl = flip(s); vblInit = vbl;
			while vbl <= vblInit + presentationTime
				draw(m);
				vbl = flip(s);
			end

			trials(trialN).presentationTime = vbl - vblInit;

			WaitSecs(0.5);

			[x,y] = RectCenter(positions(1:4));
			[w,h] = RectSize(positions(1:4));
			t.window.X = x;
			t.window.Y = y;
			t.window.radius = [w/2,h/2];
			t.window.doNegation = true;
			fprintf('===> Choice window: X = %.1f Y = %.1f W = %.1f H = %.1f\n',x,y,w,h);
			x = []; y = []; touchedResponse = false; txt = '';

			%=============================================get response
			flush(t);
			vbl = flip(s);
			vblInit = vbl;
			while vbl <= vblInit + responseTime
				draw(m);
				drawRect(s, srect, [0.3 0.3 0.3 0.6]);
				drawRect(s, positions(1:4), colour1);
				drawRect(s, positions(5:8), colour2);
				if debug && ~isempty(x) && ~isempty(y)
					drawText(s, txt);
					[xy] = s.toPixels([x y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchedResponse, x, y] = checkTouchWindow(t);
				txt = sprintf('x=%.2f y=%.2f', x, y);
				flush(t);
				if touchedResponse == true || touchedResponse == -100
					break;
				end
			end
			flip(s);
			trials(trialN).responseTime = vbl - vblInit;
			trials(trialN).correct = touchedResponse;

			% save trial data
			save('-v7', saveName, 'trials')

			%===========================================time out
			if touchedResponse == true
				fprintf('===> CORRECT :-)\n');
				if debug; drawTextNow(s,'CORRECT!'); end
				rM.stepper(46);
				WaitSecs(0.25);
			else
				drawBackground(s,[1 0 0]);
				if touchedResponse == -100
					if debug; drawText(s,'EXCLUDE!'); end
					fprintf('===> EXCLUDE :-(\n');
				else
					if debug; drawText(s,'TIMEOUT!'); end
					fprintf('===> TIMEOUT :-(\n');
				end
				flip(s);
				WaitSecs(timeOut);
			end
			drawBackground(s);
			flip(s);
		end % while keepRunning

		drawText(s, 'FINISHED!');
		flip(s);

		% save trial data
		disp('=======================================');
		fprintf('===> Saving data to %s\n',saveName)
		disp('=======================================');
		save('-v7', saveName, 'trials');
		WaitSecs(0.5);

		try Listenchar(0); end
		try Priority(0); end
		try reset(m); reset(c1); end
		close(s);
		close(t);
		close(rM);
		sca;

	catch ME
		getReport(ME);
		try reset(m); reset(c1); end
		try close(s); end
		try close(t); end
		try close(rM); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
	end

end
