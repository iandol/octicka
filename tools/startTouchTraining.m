function startTouchTraining(tr)
	pixelsPerCm = tr.density;
	distance = tr.distance;
	timeOut = tr.timeOut;
	rewardPort = '/dev/ttyACM0';
	negation = false;
	windowed = [];
	sf = [];

	% =========================== debug mode?
	if tr.debug
		if max(Screen('Screens'))==0; windowed = [0 0 1600 800]; end
		sf = kPsychGUIWindow;
	end

	if IsOctave; try pkg load instrument-control; end; end


	try
		% ============================screen
		s = screenManager('blend',true,'pixelsPerCm',pixelsPerCm, 'distance', distance,...
		'backgroundColour',tr.bg,'windowed',windowed,'specialFlags',sf);

		% s============================stimuli
		if tr.task == 3;
			im = [getenv("HOME") filesep 'Documents/Monkey-Pictures']
			target = imageStimulus('size', tr.maxSize, 'fileName', im,'crop','square');
			tr.task = 2;
		else
			target = discStimulus('size', tr.maxSize, 'colour', tr.fg);
		end
		
		% t============================touch
		t = touchManager('isDummy',tr.dummy);
		t.window.doNegation = true;
		t.window.negationBuffer = 1;
		t.drainEvents = true;
		if tr.debug; t.verbose = true; end

		% ============================reward
		rM = gpioManager;
		rM.reward.pin = 27;
		rM.reward.time = 0.025;
		try open(rM); end

		% ============================steps table
		sz = linspace(tr.maxSize, tr.minSize, 5);

		if tr.task == 2 % simple task
			if tr.phase > 9; tr.phase = 9; end
			pn = 1;
			%size
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% position
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = 11; pn = pn + 1;
		else
			pn = 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(pn); p(pn).hold = 0.05; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% 6
			p(pn).size = sz(end); p(pn).hold = 0.1;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.2;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.4;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 0.8;   p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = 1;     p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 3; p(pn).pos = [0 0]; pn = pn + 1;
			% 12
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 2; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.75; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.5; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1.25; p(pn).pos = [0 0]; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = [0 0]; pn = pn + 1;
			% 17
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 3; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 5; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 7; pn = pn + 1;
			p(pn).size = sz(end); p(pn).hold = [1 2]; p(pn).rel = 1; p(pn).pos = 11; pn = pn + 1;
		end


		% ============================setup
		sv = open(s);
		aspect = sv.width / sv.height;
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
		if ~tr.debug; HideCursor; end
		txt = 'Waiting for touch...';
		keepRunning = true
		trialN = 0;
		phaseN = 0;
		timeOut = 2;
		phase = tr.phase;

		while keepRunning
			if phase > length(p); phase = length(p); end
			if length(p(phase).pos) == 2
				x = p(phase).pos(1);
				y = p(phase).pos(2);
			else
				x = randi(p(phase).pos(1));
				if rand > 0.5; x = -x; end
				y = randi(p(phase).pos(1));
				y = y / aspect;
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

			res = 0;
			touchStart = false; keepRunning = true;
			touchResponse = '';
			anyTouch = false;
			txt = '';
			trialN = trialN + 1;
			hldtime = false;
			reset(t);
			flush(t); 
			WaitSecs(0.01);
			vbl = flip(s); vblInit = vbl;
			while ~touchStart && vbl < vblInit + 4;
				if ~hldtime; draw(target); end
				if tr.debug && ~isempty(t.x) && ~isempty(t.y)
					drawText(s, txt);
					[xy] = s.toPixels([t.x t.y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				vbl = flip(s);
				[touchResponse, hld, hldtime, rel, reli, se, fail, tch] = testHoldRelease(t,'yes','no');
				if tch
					anyTouch = true;
				end
				txt = sprintf('Step=%i Touch=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i %.1f Init: %.2f Hold: %.2f Release: %.2f',...
					phase,touchResponse,t.x,t.y,hld, hldtime, rel, reli, se,...
					t.window.radius,t.window.init,t.window.hold,t.window.release);
				if ~isempty(touchResponse); touchStart = true; break; end
				[~,~,c] = KbCheck();
				if c(quitKey); keepRunning = false; break; end
			end

			vblEnd = flip(s);
			WaitSecs(0.05);

			if anyTouch == false
				fprintf('===> TIMEOUT :-)\n');
				drawText(s,'TIMEOUT!');
				flip(s);
				WaitSecs(0.5+rand);
			elseif strcmp(touchResponse,'yes')
				giveReward(rM);
				update(d,true,phase,trialN,vblEnd-vblInit);
				phaseN = phaseN + 1;
				fprintf('===> CORRECT :-)\n');
				drawText(s,'CORRECT!');
				Beeper(3000,0.3,0.2);
				flip(s);
				WaitSecs(0.5+rand);
			elseif strcmp(touchResponse,'no')
				update(d,false,phase,trialN,vblEnd-vblInit);
				phaseN = phaseN + 1;
				fprintf('===> FAIL :-(\n');
				drawBackground(s,[1 0 0]);
				drawText(s,'FAIL!');
				flip(s);
				Beeper(300,1,0.5);
				WaitSecs(timeOut);
			else
				fprintf('===> UNKNOWN :-|\n');
				drawText(s,'UNKNOWN!');
				flip(s);
				WaitSecs(0.5+rand);
			end
			
			if isa(target,'imageStimulus')
				i.selectionOut = randi(target.nImages);
				update(i);
			end

			if trialN >= 10
				if length(d.data.result)>10
					res = sum(d.data.result(end-9:end));
				end
				fprintf('===> Performance: %i Phase: %i\n',res,phase);
				if phaseN >= 10 && length(d.data.result)>10
					if res >= 8
						phase = phase + 1;
					elseif res <= 2
						phase = phase - 1;
					end
					phaseN = 0;
					if phase < 1; phase = 1; end
					if phase > 20; phase = 20; end
					if tr.task == 2 && phase > 9; phase = 9; end
					fprintf('===> Phase update: %i\n',phase);
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

		ListenChar(0); Priority(0); ShowCursor;
		try reset(target); end
		try close(s); end
		try close(t); end
		try close(rM); end
		sca;

	catch ME
		getReport(ME);
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
	end

end
