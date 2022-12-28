movieList = {'~/Videos/testcage/ball3-0120.mkv','~/Videos/testcage/ball2-0120.mkv',...
'~/Videos/testcage/ball-0120.mkv','~/Videos/testcage/throw-0120.mkv','~/Videos/testcage/throw2-0120.mkv',...
'~/Videos/testcage/throw3-0120.mkv'};
positionList ={...
	[-20 -14 -13 -3 -20 4 -13 15.2],...
	[-20 -14 -13 -3 -20 4 -13 15.2],...
	[-20 -14 -13 -3 -20 4 -13 15.2],...
	[-19 0.5 -12.5 5 -19 6.3 -12.5 10.7],...
	[-19 1.2 -12.3 5.5 -19.5 7.2 -13 11.5],...
	[-19.5 -1 -12.5 3.5 -19.5 7 -13 12]};
for i = 1 : length(movieList)
	movieList{i} = regexprep(movieList{i}, '^~\/', [getenv('HOME') filesep]);
end

s = screenManager('blend',true,'pixelsPerCm',32,'windowed',[]);
		
% s============================stimuli
m = movieStimulus('angle',90,'loopStrategy',0);

sv = open(s);

nextKey = KbName('space');
quitKey = KbName('escape');
RestrictKeysForKbCheck([nextKey quitKey]);

try Priority(1); end

for i = 1:length(movieList);
	
	reset(m);
	m.fileName = movieList{i};
	pos = positionList{i};
	setup(m,s);
	presentationTime = m.duration;
	loop = true;
	a = 1;
	while loop
		
		draw(m);
		drawRect(s,pos(1:4),[1 1 0 0.3]);
		drawRect(s,pos(5:8),[0 1 0 0.3]);
		flip(s);
		[x,y,b] = GetMouse(s.win);
		if any(b)
			X = s.toDegrees(x,'x');
			Y = s.toDegrees(y,'y');
			fprintf('%i -- X = %.2f Y = %.2f file = %s\n',a,X,Y,m.fileName);
			WaitSecs(0.02);
			a = a + 1;
		end
		[~,~,c] = KbCheck(-1);
		if c(nextKey); break; end
		if c(quitKey);loop = false; break; end
		
	end
	
	
end

reset(m);
close(s);
sca
	