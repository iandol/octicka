function playMovies(folder)
	
	movieList = {'/home/cog/Ball.mkv'};
	
	try 
		s = screenManager('blend',true,'pixelsPerCm',80,'windowed',[0 0 800 800],'specialFlags', []);
		
		c1 = discStimulus('size',10);
		c2 = discStimulus('xPosition',-7,'yPosition',-5,'size',5,'colour',[1 0.5 0]);
		c3 = discStimulus('xPosition',7,'yPosition',-5,'size',5,'colour',[0 1 1]);
		m = movieStimulus('fileName',movieList{1},'angle',90);
		
		t = touchManager('isDummy',true);
		
		rM = arduinoManager('port','/dev/ttyACM0');
		open(rM);		
		
		
		sv = open(s);
		setup(m, s);
		setup(c1, s);
		setup(c2, s);
		setup(c3, s);
		
		t.window = struct('X',c1.xPosition,'Y',c1.yPosition,'radius',c1.size);
		setup(t,s);
		createQueue(t);
		start(t);
		
		quitKey = KbName('escape');
		RestrictKeysForKbCheck([quitKey]);
		ListenChar(-1);
		Priority(1);
		
		txt = 'Waiting for touch...';
		keepRunning = true
		
		while keepRunning
			flush(t);
			% wait for an initiate touch
			x = []; y = []; touched = false;
			touchStart = false;
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
				if c(quitKey)
				
			end
			
			flip(s)
			WaitSecs(0.5);
			
			%show movie
			for iLoop = 1:sv.fps*2;
				draw(m);
				animate(m);
				flip(s);
			end
			
			t.window = struct('X',c2.xPosition,'Y',c2.yPosition,'radius',c2.size);
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
				[touched, x, y] = checkTouchWindow(t);
				txt = sprintf('x=%.2f y=%.2f', x, y);
				flush(t);
				if touched == true;
					flip(s);
					drawTextNow(s,'CORRECT!');
					rM.timedTTL(6,50);
					break;
				end
			end
			
		end

		drawText(s, 'FINISHED!');
		flip(s);
		Listenchar(0); Priority(0);
		WaitSecs(0.5);
		close(s);
		close(t);
		close(rM);
		reset(m); reset(c1); reset(c2); reset(c3);
		sca;
	
	catch ME
		try close(s); end
		try close(t); end
		try close(rM); end
		Priority(0);ListenChar(0);
		sca;
		rethrow(ME);
	end

	
end