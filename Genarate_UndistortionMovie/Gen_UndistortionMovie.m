%{
Script to correct lens distortion.

<prepares>
*Video file(s)
*'Params_LensDistortion.mat': Parameters of lens distortion. Check the folder "Undistortion(fifeye calibration)"
 
<Procedure>
1. Get rescale parameter, so the image size (pixel) is kept on undistorition file.
2. (Optiona1) Fill any desired are with black color
3. Make undistortion movie with contrast adjustment and spatial croping.

<Memo>
Making movie in matlab takes much time than Python.
Python script for same content will be soon (7/Sep-22).
%}

%%
clc; clear all; close all

dir_Script = pwd;
dir_VideoLoad = [pwd,'/Movie_raw(distortion)'];
dir_VideoSave = [pwd,'/Movie_raw(distortion)-save'];
mkdir(dir_VideoSave)

path_Params_LensDistortion = ['Your Local','\VideoEditor\Undistortion(fifeye calibration)/Params_LensDistortion.mat'];
load(path_Params_LensDistortion)

list = dir([dir_VideoLoad,'/*.mp4']); %get info of raw movies

%%
for i = 1 : size(list,1)
    
    videoname = getfield(list,{i},'name');
    v = VideoReader([dir_VideoLoad '/',videoname ]); %load video
    
    %% calculate rescale parameter
    switch exist([dir_Script,'/ParamsMovieEdit.mat'])
        case 0
            %%% Undistortion %%% 
            frame_undistortion = undistortFisheyeImage(read(v,1),Params_LensDistortion.Intrinsics,'OutputView','full');
            if size(frame_undistortion,1) > size(read(v,1),1) %For sometimes when undistortion image becomes much larger in pixel size.
                resize = ones(size(frame_undistortion,1));
                while size(resize,1) > size(read(v,10),1)
                    scale_ratio = scale_ratio-0.0025;
                    resize =  imresize(frame_undistortion, scale_ratio);
                end
            else
                scale_ratio = 1;
                resize =  imresize(frame_undistortion, scale_ratio);
            end
            
            %%% fill area (optional)%%% 
            gray = rgb2gray(resize);
            gca = imshow(gray);
            roi = drawpolygon; %Left click for making polygon; Right click for finishing surrounding.
            mask = createMask(roi); close
            Index_fillblack = find(mask == 0);
            
            %%% save parameters %%% 
            ParamsMovieEdit.resize_scale_ratio = scale_ratio;
            ParamsMovieEdit.Index_fillblack = Index_fillblack;
            save([dir_Script,'/ParamsMovieEdit.mat'],'ParamsMovieEdit');
            clear gray frame_distortion mask resize
        case 2
            load([dir_Script,'/ParamsMovieEdit.mat']);
    end
    
    %% make undistortion movie
    
    savename_Undis = [dir_VideoSave,'/Undistortion_',videoname];
    newvideo_Undis = VideoWriter(savename_Undis,'MPEG-4');
    newvideo_Undis.FrameRate = v.FrameRate;
    newvideo_Undis.Quality = 100;
    open(newvideo_Undis)
    
    savename_UndisFill = [dir_VideoSave,'/Undistortion-Filled_',videoname];
    newvideo_UndisFill = VideoWriter(savename_UndisFill,'MPEG-4');
    newvideo_UndisFill.FrameRate = v.FrameRate;
    newvideo_UndisFill.Quality = 100;
    open(newvideo_UndisFill)

    
    k = 0; %counter
    for ii = 1 : v.NumFrames
        k = k + 1;       
        
        frame_undistortion = undistortFisheyeImage(read(v,ii),Params_LensDistortion.Intrinsics,'OutputView','full');
        frame_undistortion_res_gray = rgb2gray(imresize(frame_undistortion, ParamsMovieEdit.resize_scale_ratio));
        %frame_undistortion_res_gray_crop = frame_undistortion_res_gray(380:1300,560:1475); %Option. If you want to crop, input areas.
        frame_undistortion_res_gray_crop_imadjust = imadjust(frame_undistortion_res_gray); %imadjust(frame_undistortion_res_gray_crop)
        
        frame_undistortion_res_gray_crop_imadjust_fill = frame_undistortion_res_gray_crop_imadjust;
        frame_undistortion_res_gray_crop_imadjust_fill(ParamsMovieEdit.Index_fillblack) = 0;
        
        writeVideo(newvideo_Undis,frame_undistortion_res_gray_crop_imadjust)
        writeVideo(newvideo_UndisFill,frame_undistortion_res_gray_crop_imadjust_fill)
        
        clearvars frame*
        
        switch k == 100 %counter
            case 1
                disp(['Frame: ', num2str(ii),'/' num2str(v.NumFrames),...
                    ';  file: ', num2str(i),'/',num2str( size(list,1))])
                k = 0;
        end
    end
    close(newvideo_Undis)
    close(newvideo_UndisFill)
end
