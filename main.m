%clear,clc;

%PARAMETERS:
%The Interval between tracers. After ___ frames a tracer will appear.
tracerparam = 15;%frames per tracer (3 seconds ~ 90 frames) 
%startparam = 30;%first frame at which tracers will appear BUG
vidObj1 = VideoReader('AJ_JY_Sample_out.avi');%black and white segmented video
vidObj2 = VideoReader('AJ_JY_Sample.mp4');%base color video
workingDir = 'D:\Documents\MATLAB\NewFolder\images';%where do you want your images and video


%PART 1: Process video
vidHeight1 = vidObj1.Height;
vidWidth1 = vidObj1.Width;

vidHeight2 = vidObj2.Height;
vidWidth2 = vidObj2.Width;

%store frames into structs 's' and 't'
s = struct('cdata',zeros(vidHeight1,vidWidth1,4,'uint8'),...
    'colormap',[]);

t = struct('cdata',zeros(vidHeight2,vidWidth2,4,'uint8'),...
    'colormap',[]);

k = 1;
while hasFrame(vidObj1)
    s(k).cdata = readFrame(vidObj1);
    k = k+1;
end
j = 1;
while hasFrame(vidObj2)
    t(j).cdata = readFrame(vidObj2);
    j = j+1;
end

%testing code - read in a testing png
%x = imread('627.png');
%y = imread('627c.png');

%topright = impixel(x, 1920, 1080);%use whos x for magic numbers. used to
%determine black

%PART 2: construct and write alpha (transparency) matrix

%go through black and white image x, if its black then make it transparent
%in color image
u = struct('cdata',zeros(vidHeight2,vidWidth2,4,'uint8'),...%this struct will hold the transparency information
    'colormap',[]);
[M,N,O] = size(s(1).cdata);
black = 1;%our black and white image has 1 as black, not 0
for l=1:k-1
    x = s(l).cdata;
    A = zeros(M,N);
    for i=1:M
        for j=1:N
            red = x(i,j,1);
            green = x(i,j,2);
            blue = x(i,j,3);
            if red == black && green == black && blue == black
                A(i,j) = 1;
            end
        end
    end
    u(l).cdata = A;
end


v = struct('cdata',zeros(vidHeight2,vidWidth2,4,'uint8'),...
    'colormap',[]);

maxtracers = floor((k)/tracerparam);
%frames 1-151 stay vanilla
%frames 152-252 now have 1 tracer
%frame 152 has frame 1 behind it, frame 153 has frame 2 behind it, etc.
for vanilla=1:tracerparam%no tracers/portion of the video that IS the original video.
    v(vanilla).cdata = t(vanilla).cdata;
end

for var1=tracerparam+1:k-2%start of tracers
    bottombool=0;
    for n = maxtracers:-1:0%go backwards, so the earliest tracer will be on bottom
        if var1-n*tracerparam > 0%if the tracer doesnt go into negative time
            if bottombool == 0
                stackbottom = t(var1-n*tracerparam).cdata;%this is therefore earliest tracer, so our starting point
                bottombool = 1;
            end
            for var2=1:M%for each pixel
                for var3=1:N
                    tran = u(var1-n*tracerparam).cdata;%transparency matrix
                    stack = t(var1-n*tracerparam).cdata;%this is the tracer frame
                    if tran(var2,var3) ~= 1%if at this pixel, it is not transparent
                        stackbottom(var2,var3,1) = stack(var2,var3,1);%then overwrite current pixels
                        stackbottom(var2,var3,2) = stack(var2,var3,2);
                        stackbottom(var2,var3,3) = stack(var2,var3,3);
                    end
                end
            end
        end
    end
    if bottombool == 1
        v(var1).cdata = stackbottom;%the frame now at time var1 will have tracers
    end
end
    
%workingDir = 'D:\Documents\MATLAB\NewFolder\TEST_1';
outputVideo = VideoWriter(fullfile(workingDir,'tracer_out.avi'));
outputVideo.FrameRate = vidObj2.FrameRate;
open(outputVideo)

%code to write out images

a1 = 1;
while a1~=k-2
    imwrite(v(a1).cdata, fullfile(workingDir,strcat(num2str(a1),'.jpg')));
    a1 = a1+1;
end

for ii = 1:k-3
    img = imread(fullfile(workingDir,strcat(num2str(ii),'.jpg')));
    writeVideo(outputVideo,img)
end

close(outputVideo)