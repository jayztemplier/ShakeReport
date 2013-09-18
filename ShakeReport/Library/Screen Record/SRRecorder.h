//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRVideoWriter.h"
#import "SRDefines.h"

/*!
 The CRRecorder records the screen, user input and audio.
 */
@interface SRRecorder : NSObject {
  SRVideoWriter *_videoWriter;
  CRRecorderOptions _options;
  NSString *_albumName;
  NSTimer *loopRecordTimer;
}

/*!
 The album name for the camera roll, where videos are saved. 
 Defaults to nil, the default Camera Roll.
 */
@property (strong) NSString *albumName;

@property (nonatomic, copy) NSString *lastVideoName;

/*!
 @result Recorder.
 */
+ (SRRecorder *)sharedRecorder;

/*!
 Start the recording, with a max duration time. After the n seconds, the video restart to record the screen and erase the previous one.
 @param duration Max duration of a video.
 @param error Out error
 @result YES if started succesfully, NO otherwise
 */
- (BOOL)startWithMaxVideoDuration:(NSTimeInterval)duration error:(NSError **)error;

/*!
 Start the recording.
 @param error Out error
 @result YES if started succesfully, NO otherwise
 */
- (BOOL)start:(NSError **)error;

/*!
 Stop the recording.
 @param error Out error
 @result YES if started succesfully, NO otherwise
*/
- (BOOL)stop:(NSError **)error;

/*!
 @result YES if recording, NO otherwise
 */
- (BOOL)isRecording;

/*!
 Set recording options. Throws an exception if recording is in progress.
 @param options Recording options
 @exception CRException If recording, an exception is thrown.
 */
- (void)setOptions:(CRRecorderOptions)options;

/*!
 Save the video to the camera roll.
 
 Video can only be saved if it exists; the writer was started and stopped.
 
 @param resultBlock After successfully saving the video
 @param failureBlock If there is a failure
 */
- (void)saveVideoToAlbumWithResultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock;

/*!
 Save the video to the album with name.
 If the album doesn't exist, it is created.
 
 The video is also saved to the camera roll.
 
 @param name Album name
 @param resultBlock After successfully saving the video
 @param failureBlock If there is a failure
 */
- (void)saveVideoToAlbumWithName:(NSString *)name resultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock;

/*!
 Discard the video.
 @param error Out error
 @result YES if discarded, NO if there was an error
 */
- (BOOL)discardVideo:(NSError **)error;

- (NSString *)screenCaptureVideoPath;
- (void)mergeVideos;
- (void)mergeVideosAtPath:(NSString *)pathAsset1 andPath:(NSString *)pathAsset2 inVideoAtPath:(NSString *)mergedVideoPath;
@end
