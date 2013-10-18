:: Takes an "interwoven" NETmc video (.pkt format) and "unweaves" it.
:: Uses FFMPEG to split the "interwoven" video.pkt into individual JPEG files.
:: Each frame from each camera is appropriately named and numbered.
:: FFMPEG used to concatenate each frame from each camera into a distinct "unwoven" video.

@echo off
SETLOCAL enableextensions enabledelayedexpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::: These variables need to be set by the user ::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Output directory for FFMPEG splitting "video to images"
SET FFMPEG_IMG_DIR=output_ffmpeg
:: Output frames from each camera appropriately named and numbered
SET OUTPUT_DIR=output_batch
:: Consecutive frames from each camera in the original video
SET CONSEC_CAMERA_FRMS=6
:: Frame rate of "interwoven" video.pkt
SET VID_FRM_RATE=25
:: Precision (amount of digits) used for numbering frames in the video
SET FILENAME_PAD_PRECISION=7

:: Batch variables
SET AZERO=0
SET THEPAD=0
SET /A STBD_FLAG=1
SET /A CENTRE_FLAG=0
SET /A PORT_FLAG=0
SET /A COUNT_CONSEC_CAMERA_FRMS=1
SET /A TARGET_CONSEC_CAMERA_FRMS=%CONSEC_CAMERA_FRMS%+1
SET /A STBD_COUNTER=0
SET /A CENTRE_COUNTER=0
SET /A PORT_COUNTER=0
SET DEBUG="yes"

:: Empty the output directories
DEL %FFMPEG_IMG_DIR%\*.jpg
DEL %OUTPUT_DIR%\*.jpg

:: Use FFMPEG to strip the video into individual images
ffmpeg -y -i mpeg1_3ch.mpg -r %VID_FRM_RATE% -qscale:v 1 %FFMPEG_IMG_DIR%/ffimage.%%%FILENAME_PAD_PRECISION%d.jpg

:: Create zero padding for camera {stbd,centre,port} frame numbers
for /L %%x in (1,1,%FILENAME_PAD_PRECISION%) do (
	:: The following ensures THEPAD has one more zero than FILENAME_PAD_PRECISION (this is chopped later)
	SET THEPAD=!AZERO!!THEPAD!
)

:: Iterate over the .jpg images created by FFMPEG
for %%i in (%FFMPEG_IMG_DIR%\*.jpg) do (
	SET FFMPEG_IMG_NAME=%%i
	SET FRM2WRITE=""
	
	:: Sequentially number the different camera {stbd,centre,port} frames
	if !STBD_FLAG! EQU 1 (
		SET PADDED_STBD_COUNTER=!THEPAD!!STBD_COUNTER!
		SET PADDED_STBD_COUNTER=!PADDED_STBD_COUNTER:~-%FILENAME_PAD_PRECISION%!
		SET FRM2WRITE=stbd!PADDED_STBD_COUNTER!
		SET /A STBD_COUNTER+=1
	) else if !CENTRE_FLAG! EQU 1 (
		SET PADDED_CENTRE_COUNTER=!THEPAD!!CENTRE_COUNTER!
		SET PADDED_CENTRE_COUNTER=!PADDED_CENTRE_COUNTER:~-%FILENAME_PAD_PRECISION%!
		SET FRM2WRITE=centre!PADDED_CENTRE_COUNTER!
		SET /A CENTRE_COUNTER+=1
	) else if !PORT_FLAG! EQU 1 (
		SET PADDED_PORT_COUNTER=!THEPAD!!PORT_COUNTER!
		SET PADDED_PORT_COUNTER=!PADDED_PORT_COUNTER:~-%FILENAME_PAD_PRECISION%!
		SET FRM2WRITE=port!PADDED_PORT_COUNTER!
		SET /A PORT_COUNTER+=1	
	) else (
		echo.
		echo.ERROR: logical Stbd Centre Port frm2write error
		EXIT /B
	)
	if !DEBUG!=="yes" (
		echo.count_consec_camera_frms=!COUNT_CONSEC_CAMERA_FRMS!
		echo.!FFMPEG_IMG_NAME!
		echo.!OUTPUT_DIR!\!FRM2WRITE!.jpg
	)
	:: Write/copy the sequentially numbered camera {stbd,centre,port} frame to file
	COPY /Y !FFMPEG_IMG_NAME! !OUTPUT_DIR!\!FRM2WRITE!.jpg
	
	:: Change camera flag {stbd,centre,port} every CONSEC_CAMERA_FRMS
	:: This let's us know which camera the frame belongs to
	SET /A COUNT_CONSEC_CAMERA_FRMS+=1
	if !COUNT_CONSEC_CAMERA_FRMS! EQU !TARGET_CONSEC_CAMERA_FRMS! (
		SET /A COUNT_CONSEC_CAMERA_FRMS=1
		if !STBD_FLAG! EQU 1 (
			SET /A STBD_FLAG=0
			SET /A CENTRE_FLAG=1
			SET /A PORT_FLAG=0
		) else if !CENTRE_FLAG! EQU 1 (
			SET /A STBD_FLAG=0
			SET /A CENTRE_FLAG=0
			SET /A PORT_FLAG=1
		) else if !PORT_FLAG! EQU 1 (
			SET /A STBD_FLAG=1
			SET /A CENTRE_FLAG=0
			SET /A PORT_FLAG=0
		) else (
			echo.
			echo.ERROR: logical Stbd Centre Port flag error
			EXIT /B
		)
		if !DEBUG!=="yes" (
			echo.
			echo.the_stbd_flag=!STBD_FLAG!
			echo.the_centre_flag=!CENTRE_FLAG!
			echo.the_port_flag=!PORT_FLAG!
		)
	)
)

:: Use FFMPEG to create a Motion JPEG video in an AVI container for each camera {stbd,centre,port}
:: FFMPEG is concatenating the JPEG images from each camera {stbd,centre,port} into a seperate video file
ffmpeg -y -f image2 -i %OUTPUT_DIR%\stbd%%%FILENAME_PAD_PRECISION%d.jpg -r %VID_FRM_RATE% -codec copy output_stbd.avi
ffmpeg -y -f image2 -i %OUTPUT_DIR%\centre%%%FILENAME_PAD_PRECISION%d.jpg -r %VID_FRM_RATE% -codec copy output_centre.avi
ffmpeg -y -f image2 -i %OUTPUT_DIR%\port%%%FILENAME_PAD_PRECISION%d.jpg -r %VID_FRM_RATE% -codec copy output_port.avi

ENDLOCAL
