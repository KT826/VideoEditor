%{ 
<Calibraion of lens Distortion (fisheye calibration)>
Equipments here: 
Lens: VS-0814H1-SWIR
Camera: acA2040-90umNIR

Matlab R2020b
reference: https://jp.mathworks.com/help/vision/ug/fisheye-calibration-basics.html
%}

%% load images 
clc; clear all; close all
ScriptPath = pwd;
ImagePath = [ScriptPath, '\CalibrationImages']; %path of calibration images set
images = imageDatastore(ImagePath);
[imagePoints,boardSize] = detectCheckerboardPoints(images.Files); %imagePoints: XY coordinates of borders b/w cheakers

%% plots of detected borders (optional)
close all
savepath = [ScriptPath, '/CalibrationImages_detected'];
mkdir(savepath)

for i = 1 : numel(images.Files)
    figure
    imshow(imread(images.Files{i}));    
    hold on
    for ii = 1 : size(imagePoints,1)
        scatter(imagePoints(ii,1,i),imagePoints(ii,2,i),'y.')
        hold on
    end
    
    savename = ['#',num2str(i)];
    title(savename)
    saveas(gca,[savepath,'/',savename,'.tiff'],'tiff')
    close
end

%% get parameter to correct distortion
CheckerSize = 22; %should be integer in millimeter (22mm in my setup)
WorldPoints = generateCheckerboardPoints(boardSize,CheckerSize);
imageSize = [size(readimage(images,1),1) size(readimage(images,1),2)];
Params_LensDistortion = estimateFisheyeParameters(imagePoints,WorldPoints,imageSize);
save([ScriptPath,'/Params_LensDistortion.mat'],'Params_LensDistortion')

%% Optional: check the correction quality
%make gif image
close all
clear frame
savename = 'Result.gif'; % save name 

for i = 1 : 2
    switch i
        case 1 %original image
            img = readimage(images,1); %original image
            tx = 'original image';
        case 2 %undistortion imafe
            img0 = readimage(images,1);
            img = undistortFisheyeImage(img0,Params_LensDistortion.Intrinsics,'OutputView','full');
            tx = 'undistortion';
    end
    
    imshow(img,'InitialMagnification','fit','Border','tight')
    text(size(img,1)/2,size(img,2)/2,tx,'Color','white','FontSize',14)
    drawnow
    frame = getframe(1);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    
    if i == 1
        imwrite(imind,cm,savename,'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,savename,'gif','WriteMode','append');
    end 
end
close 
