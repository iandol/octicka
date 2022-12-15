function playMovies(folder)
	
	% ============================movie / position list
	movieList = {'/home/cog/Code/octicka/tests/ball.mkv','/home/cog/Code/octicka/tests/ball.mkv'};
	positionList = {-4, 4};
	
	try 
		% ============================screen
		s = screenManager('blend',true,'pixelsPerCm',80,'windowed',[0 0 1200 800],'specialFlags', [32]);
		
		% s============================timuli
		rn = 1;
		m = movieStimulus('fileName',movieList{rn},'angle',90);
		c1 = discStimulus('size',4);
		c2 = discStimulus('xPosition',-4,'yPosition',positionList{rn},'size',4,'colour',[1 0.5 0 0.75]);
		c3 = discStimulus('xPosition',-4,'yPosition',-positionList{rn},'size',4,'colour',[0 1 1 0.75]);

		% t============================ouch
		t = touchManager('isDummy',true);
		
		% ============================reward
		rM = arduinoManager('port','/dev/ttyACM0');
		open(rM);		
		
		% ============================setup
		sv = open(s);
		setup(m, s);
		setup(c1, s);
		setup(c2, s);
		setup(c3, s);
		setup(t,s);
		createQueue(t);
		start(t);
		
		% ============================settings
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		try ListenChar(0); end
		try Priority(1); end
		txt = 'Waiting for touch...';
		keepRunning = true
		trialN = 0;
		
		while keepRunning	
			%make our touch window around stimulus c1
			t.window = struct('X',c1.xPosition,'Y',c1.yPosition,'radius',c1.size/2);
			x = []; y = []; touched = false; touchedResponse = false;
			trialN = trialN + 1;
			touchStart = false;
			fprintf('\n===> START TRIAL: %i\n');
			flush(t);
			% wait for an initiate touch
			while ~touchStart
				drawText(s, txt);
				draw(c1);
				if ~isempty(x) && ~isempty(y)
					[xy] = s.toPixels([x y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				flip(s);
				[touched, x, y] = checkTouchWindow(t);
				txt = sprintf('Touch = %i x=%.2f y=%.2f',touched,x,y);
				flush(t);
				if touched
					touchStart = true;
				end
				[~,~,c] = KbCheck(-1);
				if c(quitKey); keepRunning=false; break; end
			end
			
			flip(s)
			WaitSecs(0.5);
			
			if keepRunning == false; break; end
			
			%show movie
			for iLoop = 1:sv.fps*2;
				draw(m);
				animate(m);
				flip(s);
			end
			
			x = s.toDegrees(c2.xFinal,'x');
			y = s.toDegrees(c2.yFinal,'y');
			t.window = struct('X',x,'Y',y,'radius',c2.size/2);
			fprintf('===> Choice window: X = %.1f Y = %.1f\n',x,y);
			flip(s);
			WaitSecs(0.1);
			flush(t);
			x = []; y = []; touched = false;
			%get response
			for iLoop = 1 : sv.fps*2;
				draw(c2); draw(c3);
				if ~isempty(x) && ~isempty(y)
					[xy] = s.toPixels([x y]);
					Screen('glPoint', s.win, [1 0 0], xy(1), xy(2), 10);
				end
				flip(s);
				[touchedResponse, x, y] = checkTouchWindow(t);
				txt = sprintf('x=%.2f y=%.2f', x, y);
				flush(t);
				if touchedResponse == true;
					drawTextNow(s,'CORRECT!');
					rM.timedTTL(6,50);
					WaitSecs(0.25);
					break;
				end
			end
			
			rn = randi(length(movieList));
			reset(m);
			m.fileName = movieList{rn};
			setup(m,s);
			c2.yPositionOut = positionList{rn};
			c3.yPositionOut = -positionList{rn};
			update(c2); update(c3);
			fprintf('===> Choosing Movie %i = %s\n',rn, m.fileName);
			fprintf('===> S:%i c2 Y = %.1f | c3 Y = %.1f\n',rn,c2.yPositionOut,c3.yPositionOut);
			
			if ~touchedResponse
				drawBackground(s,[1 0 0]);
				drawTextNow(s,'TIMEOUT!');
				WaitSecs(2);
				drawBackground(s,s.backgroundColour);
				flip(s);
			end
		end

		drawText(s, 'FINISHED!');
		flip(s);
		try Listenchar(0); end
		try Priority(0); end
		WaitSecs(0.5);
		try reset(m); reset(c1); reset(c2); reset(c3); end
		close(s);
		close(t);
		close(rM);
		sca;
		
	catch ME
		try reset(m); reset(c1); reset(c2); reset(c3); end
		try close(s); end
		try close(t); end
		try close(rM); end
		try Priority(0); end
		try ListenChar(0); end
		sca;
		rethrow(ME);
	end

end