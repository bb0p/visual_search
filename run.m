% Code for conducting Linguistic Visual Search experiments

% A table of stimuli is prepared, and for each execution of the function
% vs_KeyPressFcn a response table is prepared and by the end of the
% experiment this table is written to a file with the prefix "subject"

% Use any key to get the next stimuli and 0 and 1 to indicate absence and
% presence

function vs_uipanel
global width height margin mindist long short green im c m samplingrate...
    s response breathe semaphore file par setsizes ss numpar...
    red green vertical horisontal first

% Design a table with experiment parameters
% positive number indicates that the parameter is included
co=1; or=2; pr=3; delay=0; order=0;
% For programming convenience the 3 first parameters are mandatory
numpar=sum([co or pr delay order]>0);  % Number of parameters
ss=numpar+1;
setsizes=[12 24]; % Set sizes

s=dec2bin([0:2^numpar-1],numpar);           % Binary strings
s=reshape(str2num(s(:)),2^numpar,numpar);   % Transform to number table
s=s+1;                                      % Transform [0 1] to [1 2]
s=repmat(s,length(setsizes),1);             % Redublicate according to number of set sizes
for i=1:length(setsizes)                    % Fill in the set sizes in first position
    s(1+(i-1)*2^numpar:i*2^numpar,numpar+1)=setsizes(i);,
end
numblock=1;                                 % Number of blocks
block=numpar+2;                             % Position indicator
s(:,block)=1;                               % First block
for i=2:numblock                            % Create more blocks if needed
    snew=s;                                 % Create another block
    snew(:,block)=i;                        % And give it a block number
    s=[s' snew']';                          % Merge
end
s(randperm(length(s)),:)=s; % Permute
size(s)
screensize  = get(0,'ScreenSize');          % Get the screen size
width       = screensize(3);                % Width of display
height      = screensize(4)-20;             % Height of display minus something for the handle
margin      =  10;                          % Minimal distance of elemenent from sides
mindist     =  10;                          % Minimal distance between elements
long        =  80;                          % Long side of element
short       =  20;                          % Short side of element
darkgreen   = 160;                          % Darker green
red         =   1;                          % Encode color and orientation
green       =   2;
vertical    =   1;
horisontal  =   2;

files=dir('sound/*.wav');                   % Read the sound files
for i=1:length(files)
    file{i}=wavread(['sound/' files(i).name]);
end
samplingrate=22050;

vs_figure = figure(...
    'Position',[0 0 width height],...
    'outerposition',[0 0 width height],...
    'KeyPressFcn',@vs_KeyPressFcn,...
    'NumberTitle','off', ...
    'MenuBar','none',...
    'ToolBar','none');
axis off
axes('position',[0  0  1  1])

semaphore   = false;                        % Only process one keypress at a time
breathe     = true;                         % Subject is either active or breathing
first       = true;                         % We need to know if this is the first time
response    = [];                           % Table to record all responses in
c           = 1;                            % Variable to count trials
tic

function vs_KeyPressFcn(hObject, eventdata, handles)
    % Central function for the experiment
    reactiontime=toc;
    % The main rythm of vs_KeyPressFcn is controlled by a variable called
    % breathe, which is true when we are waiting for the subject to press a key
    % to continue to the next trial
    currentkey =  double(get(hObject,'CurrentKey'));
    if semaphore==false
        semaphore=true; % Prevent new key presses while processing this
        if c<=length(s) % Are we done yet?
            if breathe
                breathe = false;
                im = uint8(zeros(width,height,3)+255); % Create white display and show
                image(im)
                axis off
                drawnow;
                if first==false
                    response=[response; s(c,:) currentkey(1) reactiontime];
                    c=c+1;
                end
                first=false;
            else
                breathe = true;
                % Create dot and show
                im(uint16(width/2-4):uint16(width/2+4),uint16(height/2-2):uint16(height/2+2),:)=0;
                image(im)
                axis off
                drawnow;
                % Remove dot again
                im(uint16(width/2-4):uint16(width/2+4),uint16(height/2-2):uint16(height/2+2),:)=255;
                % Create display
                if s(c,co)==red & s(c,or)==vertical         % Red vertical
                    % The call to the create_display below takes 4
                    % variables. The number of
                    % red verticals, red horisontals, green verticals,
                    % green horisontals
                    create_display(s(c,pr)-1, s(c,ss)/2-s(c,pr)+1, s(c,ss)/2, 0);
                elseif s(c,co)==red & s(c,or)==horisontal   % Red horisontal
                    create_display(s(c,ss)/2-s(c,pr)+1, s(c,pr)-1, 0, s(c,ss)/2);
                elseif s(c,co)==green & s(c,or)==vertical   % Green vertical
                    create_display(s(c,ss)/2, 0, s(c,pr)-1, s(c,ss)/2-s(c,pr)+1);
                elseif s(c,co)==green & s(c,or)==horisontal % Green horisontal
                    create_display(0, s(c,ss)/2, s(c,ss)/2-s(c,pr)+1, s(c,pr)-1);
                end;
                % Prepare for presentation
                imp = permute(im,[2 1 3]);  % Turn the image for presentation
                if order>0 % Are we using color/orientation order in this experiment
                    filenumber=4*(1-(s(c,co)-1))+2*(1-(s(c,or)-1))+(s(c,order)-1)+1;
                else % if not then default to color first
                    filenumber=4*(1-(s(c,co)-1))+2*(1-(s(c,or)-1))+1;
                end
                player=audioplayer(file{filenumber},samplingrate);
                % Critical timing paramter that might need to be
                % changed depending on OS and machinery... not pretty...
                if delay>0 % Are we using the delay parameter in this experiment?
                    if s(c,delay)==2
                        wa=1-.28; % And here it is again...
                    end;
                end
                wa=length(file{filenumber})/samplingrate-.18; % Default delay
                play(player)
                pause(wa)
                image(imp)
                axis off
                drawnow
                tic
            end; % breathe
        else % call it quits
            text(100,100,'Thank You!','Fontsize', 50)
            data = dir('subjects/subject*');
            save(['subjects/subject' int2str(length(data)+1)],'response','-ASCII');
            pause(3)
            close(vs_figure)

            % Load and analyze data
            r=zeros(2,2,2,length(setsizes),length(data),numblock,2);
            for i=1:length(data)
                t=load(['subjects/' data(i).name]);
                t(:,1:numpar)=t(:,1:numpar)+1; % Translate [0 1] into [1 2]
                for j=1:length(t)
                    t(j,numpar+1)=find(setsizes==t(j,numpar+1)); % Translate set sizes into order
                    b=1;
                    searching=true;
                    while searching % Find an empty entry in s
                        if r(t(j,1),t(j,2),t(j,3),t(j,4),i,b,1)>0
                            b=b+1;
                        else
                            r(t(j,1),t(j,2),t(j,3),t(j,4),i,b,:)=[t(j,numpar+3) t(j,numpar+4)];
                            searching=false;
                        end
                    end
                end
            end
            % Simple example of how to use this response matrix
            r2=r(:,:,:,:,:,:,2);        % Pick the reaction time
            r2=permute(r2,[4 1 2 3 5]); % Move the set size element to the front
            r2=reshape(r2,2,2*2*2*2);   % Collaps the other dimensions
            mean(r2,2)                  % Calculate the mean reaction time for each set size
        end; % quits
        semaphore=false; % Allow new keypresses again
    end; % semaphore
end % vs_KeyPressFcn

% Function for creating displays. Returns its results in im.
function create_display(rv,rh,gv,gh)
    % Put the list together
    disp([rv rh gv gh])
    list = [zeros(1,rv)+1 zeros(1,rh)+2 zeros(1,gv)+3 zeros(1,gh)+4];
    list = list(randperm(length(list))); % Permute
    % These lists could also be accumulated and saved in a file for future
    % analysis
    for i=1:length(list)
        if list(i)==1 || list(i)==3 % translate long/short into actual x,y
            xe = short;
            ye = long;
        else
            xe = long;
            ye = short;
        end;
        found = false;
        while found == false % Search for a non-overlapping point
            % Find a random point that respects margin and shape
            x = round(rand*(width-2*margin-xe)+margin+xe/2);
            y = round(rand*(height-2*margin-ye)+margin+ye/2);
            found = true; % Assume optimistically that we found it
            for j=round(x-xe/2-mindist)+1:round(x+xe/2+mindist)
                for k=round(y-ye/2-mindist)+1:round(y+ye/2+mindist)
                    if im(j,k,3) == 100;
                        found = false; % Oh well, we didn't find it...
                    end;
                end;
            end;
        end;
        % Paint yellow around the area
        im(round(x-xe/2-mindist)+1:round(x+xe/2+mindist),round(y-ye/2-mindist)+1:round(y+ye/2+mindist),3) = 100;
        % Paint the stimuli itself
        im(round(x-xe/2):round(x-xe/2)+xe,round(y-ye/2):round(y-ye/2)+ye,:) = 0;
        if list(i)==1 || list(i)==2
            im(round(x-xe/2):round(x-xe/2)+xe,round(y-ye/2):round(y-ye/2)+ye,1) = 255;
        else
            im(round(x-xe/2):round(x-xe/2)+xe,round(y-ye/2):round(y-ye/2)+ye,2) = darkgreen;
        end;
    end;
    im(find(im==100))=255; % Remove the yellow again
end;
end % vs_uipanel