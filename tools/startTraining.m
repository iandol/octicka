function startTraining(tr)
	pixelsPerCm = tr.density;
	distance = tr.distance;
	timeOut = 2;
	rewardPort = '/dev/ttyACM0';
	negation = false;

	% =========================== debug mode?
	if tr.debug
		windowed=[];if max(Screen('Screens'))==0; windowed = [0 0 1600 800]; end
		sf = kPsychGUIWindow;
		dummy = true;
	else
		windowed=[];if max(Screen('Screens'))==0; windowed = [0 0 1600 800]; end
		sf = [];
		dummy = false;
	end

	if IsOctave; try pkg load instrument-control; end; end

	try
		% ============================screen
		s = screenManager('blend',true,'pixelsPerCm',pixelsPerCm, 'distance', distance,...
		'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		target = discStimulus('size', 20, 'colour', tr.fg);

		% t============================ouch
		t = touchManager('isDummy',dummy);
		t.window.doNegation = true;
		t.negationBuffer = 2;
		if tr.debug; t.verbose = true; end

		% ============================reward
		rM = arduinoManager('port',rewardPort,'shield','new','verbose',false);
		try open(rM); end

		% ============================steps table
		pn = 1;
		p(pn).size = 20; p(pn).hold = 0.1; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 15; p(pn).hold = 0.1; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 10; p(pn).hold = 0.1; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 5; p(pn).hold = 0.1; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = 0.1; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		%
		p(pn).size = 2; p(pn).hold = 0.2; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = 0.5; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = 1.0; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = 1.5; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = 2.0; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
		%
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 2; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 1.75; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 1.5; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 1.25; p(pn).pos = [0 0]; pn = pn + 1;
		p(pn).size = 2; p(pn).hold = [1.3 2]; p(pn).rel = 1; p(pn).pos = [0 0]; pn = pn + 1;
		%
		p(pn).size = 1.5; p(pn).hold = [1.3 2]; p(pn).rel = 1; p(pn).pos = 2; pn = pn + 1;
		p(pn).size = 1.5; p(pn).hold = [1.3 2]; p(pn).rel = 1; p(pn).pos = 4; pn = pn + 1;
		p(pn).size = 1.5; p(pn).hold = [1.3 2]; p(pn).rel = 1; p(pn).pos = 8; pn = pn + 1;
		p(pn).size = 1.5; p(pn).hold = [1.3 2]; p(pn).rel = 1; p(pn).pos = 15; pn = pn + 1;

		% ============================setup
		sv = open(s);
		setup(target, s);
		setup(t, s);
		createQueue(t);
		start(t);

		% ==============================save file name
		svn = initialiseSaveFile(s);
		mkdir([s.paths.savedData filesep tr.name]);
		saveName = [ s.paths.savedData filesep tr.name filesep 'TouchT-' tr.name '-' svn '.mat'];
		d = touchData;
		d.name = saveName;
		d.subject = tr.name;

		% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		Screen('Preference','Verbosity',4);
		try Priority(1); end
		txt = 'Waiting for touch...';
		keepRunning = true
		trialN = 0;
		phaseN = 0;
		timeOut = 2;
		phase = tr.phase;

		while keepRunning

			if length(p(phase).pos) == 2
				x = p(phase).pos(1);
				y = p(phase).pos(2);
			else
				x = randi(p(phase).pos(1));
				if rand > 0.5; x = -x; end
				y = randi(p(phase).pos(1));
				if rand > 0.5; y = -y; end
			end
			if length(p(phase).hold) == 2
				t.window.hold = randi(p(phase).hold .* 1e3) / 1e3;
			else
				t.window.hold = p(phase).hold(1);
			end
			t.window.radius = p(phase).size / 2;
			t.window.init = 3;
			t.window.release = p(phase).rel;
			t.window.X = x;
			t.window.Y = y;

			target.xPositionOut = x;
			target.yPositionOut = y;
			target.sizeOut = p(phase).size;

			update(target);

			fprintf('\n===> START TRIAL: %i - PHASE %i\n', trialN, phase);
			fprintf('===> Size: %.1f Init: %.2f Hold: %.2f Release: %.2f\n', t.window.radius,t.window.init,t.window.hold,t.window.release);

			touchStart = false;
			touchResponse = '';
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			reset(t);
			flush(t);
			vbl = flip(s); vblInit = vbl;
			while ~touchStart && vbl < vblInit + 5;
				if ~hldtime; draw(target); end
				if tr.debug && ~isempty(t.x) && ~isempty(t.y)
					drawText(s, txt);
					[xy] = s.toPixels([t.x t.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchResponse, hld, hldtime, rel, reli, se] = testHoldRelease(t,'yes','no');
				txt = sprintf('Touch = %i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i',touchResponse,t.x,t.y,hld, hldtime, rel, reli, se);
				flush(t);
				if ~isempty(touchResponse); touchStart=true; break; end
				[~,~,c] = KbCheck(-1);
				if c(quitKey); keepRunning=false; break; end
			end

			vblEnd = flip(s);
			WaitSecs(0.05);

			if strcmp(touchResponse,'yes')
				update(d,true,phase,trialN,vblEnd-vblInit);
				phaseN = phaseN + 1;
				fprintf('===> CORRECT :-)\n');
				if tr.debug; drawTextNow(s,'CORRECT!'); end
				WaitSecs(0.5);
			elseif strcmp(touchResponse,'no')
				update(d,false,phase,trialN,vblEnd-vblInit);
				phaseN = phaseN + 1;
				drawBackground(s,[1 0 0]);
				fprintf('===> FAIL :-(\n');
				if tr.debug; drawTextNow(s,'FAIL!'); end
				WaitSecs(timeOut);
			else
				fprintf('===> TIMEOUT :-)\n');
				if tr.debug; drawTextNow(s,'TIMEOUT!'); end
				WaitSecs(0.25);
			end

			if trialN >= 10
				if phaseN >= 10 && length(d.data.result)>10
					res = d.data.result(end-9:end);
					if sum(res) > 8
						phase = phase + 1;
					elseif sum(res) < 2
						phase = phase - 1;
					end
					phaseN = 0;
					if phase < 1; phase = 1; end
					if phase > 20; phase = 20; end
				end
			end

			if keepRunning == false; break; end
			drawBackground(s);
			flip(s);
		end % while keepRunning

		drawText(s, 'FINISHED!');
		flip(s);

		% save trial data
		disp('=======================================');
		fprintf('===> Saving data to %s\n',saveName)
		disp('=======================================');
		save('-v7', saveName, 'd');
		WaitSecs(0.5);

		ListenChar(0); Priority(0);
		try reset(target); end
		try close(s); end
		try close(t); end
		try close(rM); end
		sca;

	catch ME
		if exist('pid','var') && ~isempty(pid)
			try system(['pkill ' pid]); end
		end
		try reset(target); end
		try close(s); end
		try close(t); end
		try close(rM); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
		disp(ME);
		for i = 1:length(ME.stack);
			disp(ME.stack(i));
		end
	end

end
