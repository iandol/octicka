function InitialTouchTraining
pixelsPerCm = 32;
timeOut = 2;
subjectName = '13';
rewardPort = '/dev/ttyACM0';
debug =true ;
if debug
    if  max(Screen('Screens'))==0
        windowed = [0 0 1000 800];
    end
    windowed = [0 0 1000 800];
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

% if IsOctave; try pkg load instrument-control; end; end

% ============================movie / position list
randomise=0;

try
    % ============================screen
    s = screenManager('blend',true,'pixelsPerCm',pixelsPerCm,'windowed',windowed,'specialFlags',sf);

    % s============================stimuli
    xPosition=0;yPosition=0;
    
    c1 = discStimulus('size',2,'colour',[1 1 1 1]);%,'xPosition',xPosition,'yPosition',yPosition);

    % t============================ouch
    t = touchManager('isDummy',dummy);
    t.window.doNegation = false;
    t.negationBuffer = 2;

    % ============================reward
%     try open(rM); end
    rM = arduinoManager('port',rewardPort,'verbose',false);

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
    try Priority(1); end
    txt = 'Waiting for touch...';
    keepRunning = true;
    trialN  = 0;
    % 		presentationTime=m.duration;
    % 		responseTime = 2;
    timeOut = 2;
    trials = struct;
    % 		srect = [sv.leftInDegrees+0.1,sv.topInDegrees+0.1,...
    % 			sv.rightInDegrees-0.1,sv.bottomInDegrees-0.1];
    system('raspi-gpio set 17 op');
    system('raspi-gpio set 27 op');
    system('raspi-gpio set 17 dl');
    system('raspi-gpio set 27 dl');

    while keepRunning
       
        if randomise
            x=-10:2:10;
            y=x;
            r=randperm(length(x),2);
            c1.xPositionOut=x(r(1));c1.yPositionOut=y(r(2));
            t.window.X = x(r(1)); % c1.xPosition;
            t.window.Y = y(r(2)); % c1.yPosition;
        else
          c1.xPosition=xPosition;c1.yPosition=yPosition=0;
          t.window.X =  c1.xPosition;
          t.window.Y =  c1.yPosition;
        end
        update(c1);
        
        t.window.radius = [c1.size/2, c1.size/2];
        t.window.doNegation = true;
        x = []; y = []; touched = false; touchedResponse = false;
        trialN = trialN + 1;
        % 			trials(trialN).movieName = m.fileName;
        positions=[c1.xPosition c1.yPosition];
        trials(trialN).targetPosition = positions;
        touchStart = false;
        fprintf('\n===> START TRIAL: %i\n', trialN);
%         fprintf('===> Chosen Movie %i = %s\n',rn, m.fileName);


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
                touchStart  = true;

            elseif touched == -100
                drawBackground(s,[1 0 0]);
                if debug; drawText(s,'EXCLUSION!'); end
                flip(s);
                WaitSecs(timeOut);
                drawBackground(s);
                continue;
            end
            [~,~,c] = KbCheck(-1);
            if c(quitKey); keepRunning=false; break; end
        end  % touchStart


        WaitSecs(0.5);
        if keepRunning == false; break; end

        %================INCORRECT================================show movie
        % 			vbl = flip(s); vblInit = vbl;
        % 			while vbl <= vblInit + presentationTime
        % 				draw(m);
        % 				vbl = flip(s);
        % 			end
        %
        % 			trials(trialN).presentationTime = vbl - vblInit;
        %
        % 			WaitSecs(0.5);

        touchedResponse = touchStart;

        trials(trialN).responseTime = vbl - vblInit;
        trials(trialN).correct = touchedResponse;

        % save trial data
        save('-v7', saveName, 'trials')

        %===========================================time out
        if touchedResponse == true
            fprintf('===> CORRECT :-)\n');
            if debug; drawTextNow(s,'CORRECT!'); end
%             rM.stepper(46);
            system('raspi-gpio set 27 dh')
            WaitSecs(0.25);
            system('raspi-gpio set 27 dl')
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
    try reset(m); reset(c1); end
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