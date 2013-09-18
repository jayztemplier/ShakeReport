//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRRecorder.h"
#import "SRUIViewRecorder.h"
#import "SRScreenRecorder.h"
#import "SRCameraRecorder.h"
#import "SRUtils.h"
#import "SRUIWindow.h"

@implementation SRRecorder

- (id)init {
  if ((self = [super init])) {
    _options = CRRecorderOptionUserCameraRecording|CRRecorderOptionUserAudioRecording|CRRecorderOptionTouchRecording;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_onEvent:) name:CRUIEventNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (SRRecorder *)sharedRecorder {
  static dispatch_once_t once;
  static id sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setOptions:(CRRecorderOptions)options {
  if (self.isRecording) [NSException raise:CRException format:@"You can't set recording options while recording is in progress."];
  _options = options;
}

- (BOOL)isRecording {
  return (_videoWriter && _videoWriter.isRecording);
}

- (void)_alert:(NSString *)message {
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [alertView show];
}

- (BOOL)startWithMaxVideoDuration:(NSTimeInterval)duration error:(NSError **)error
{
#warning TODO: Not working yet!
//    return [self start:error];
    if ([self isRecording]) {
        [self stop:error];
    }
    loopRecordTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(restart:) userInfo:nil repeats:YES];
    return [self restart:error];;
}

- (BOOL)restart:(NSError **)error
{
    if ([self isRecording]) {
        [_videoWriter stop:error];
        [_videoWriter discard:error];
    }
    [self performSelector:@selector(start:) withObject:nil afterDelay:0.2];
    return YES;
}

- (BOOL)start:(NSError **)error {  
  if ([[SRUtils machine] hasPrefix:@"iPhone5"] && [UIScreen mainScreen].bounds.size.height <= 480) {
    [self _alert:@"Recording only works with full size app on iPhone 5."];
    return NO;
  }
  
#if TARGET_IPHONE_SIMULATOR
  UIWindow *window = [SRUIWindow window];
  if (!window) {
    [NSException raise:CRException format:@"No window for recording has been setup. This probably means you are using the simulator and no CRUIWindow has been constructed. See documentation for help on setting up the CRUIWindow."];
  }
  SRUIViewRecorder *viewRecoder = [[SRUIViewRecorder alloc] initWithView:window size:window.frame.size];
#else
    UIWindow *window = [SRUIWindow window];
    if (!window) {
        [NSException raise:CRException format:@"No window for recording has been setup. This probably means you are using the simulator and no CRUIWindow has been constructed. See documentation for help on setting up the CRUIWindow."];
    }
  SRScreenRecorder *viewRecoder = [[SRScreenRecorder alloc] initWithWindow:window];
#endif
    
  _videoWriter = [[SRVideoWriter alloc] initWithRecordable:viewRecoder options:_options];
    
  if ([_videoWriter start:error]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:CRRecorderDidStartNotification object:self];
    return YES;
  }
  return NO;
}

- (void)_stopForUnregistered {
  [self stop:nil];
}

- (BOOL)stop:(NSError **)error {
    if (loopRecordTimer && [loopRecordTimer isValid]) {
        [loopRecordTimer invalidate];
        loopRecordTimer = nil;
    }
    BOOL stopped = [_videoWriter stop:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:CRRecorderDidStopNotification object:self];
    return stopped;
}

- (void)saveVideoToAlbumWithResultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock {
  return [_videoWriter saveToAlbumWithName:_albumName resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)saveVideoToAlbumWithName:(NSString *)name resultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock {
  return [_videoWriter saveToAlbumWithName:name resultBlock:resultBlock failureBlock:failureBlock];
}

- (BOOL)discardVideo:(NSError **)error {
  return [_videoWriter discard:error];
}

- (NSString * )screenCaptureVideoPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:@"screen_capture.mov"];
    return myPathDocs;
}

- (void)mergeVideos
{
    NSString *pathChunk2 = [SRUtils sr_temporaryFile:CRFileChunk2 deleteIfExists:NO error:nil];
    BOOL oneIsFirst = (![SRUtils sr_exist:pathChunk2] || [[SRRecorder sharedRecorder].lastVideoName isEqualToString:CRFileChunk2]);
    NSString *pathAsset1 = [SRUtils sr_temporaryFile:(oneIsFirst ? CRFileChunk1 : CRFileChunk2) deleteIfExists:NO error:nil];
    NSString *pathAsset2 = [SRUtils sr_temporaryFile:(oneIsFirst ? CRFileChunk2 : CRFileChunk1) deleteIfExists:NO error:nil];
    [self mergeVideosAtPath:pathAsset1 andPath:pathAsset2 inVideoAtPath:[self screenCaptureVideoPath]];
}

- (void) mergeVideosAtPath:(NSString *)pathAsset1 andPath:(NSString *)pathAsset2 inVideoAtPath:(NSString *)mergedVideoPath
{
   AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:pathAsset1] options:nil];
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    if (![[firstAsset tracksWithMediaType:AVMediaTypeVideo] count]) {
        return;
    }
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    [FirstlayerInstruction setTransform:CGAffineTransformMakeScale(0.f,0.f) atTime:firstAsset.duration];
    
    CMTimeRange videoTotalDuration;
    NSMutableArray *layerInstructions = [NSMutableArray arrayWithObject:FirstlayerInstruction];
    
    if ([SRUtils sr_exist:pathAsset2]) {
        AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:pathAsset2] options:nil];
        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        if (![[secondAsset tracksWithMediaType:AVMediaTypeVideo] count]) {
            return;
        }
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:firstAsset.duration error:nil];
        AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
        [layerInstructions addObject:SecondlayerInstruction];
        videoTotalDuration = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration));
    } else {
        videoTotalDuration = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    }
    
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = videoTotalDuration;
    MainInstruction.layerInstructions = layerInstructions;
    
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = [[[UIApplication sharedApplication].delegate window] bounds].size;
    
    NSString *myPathDocs =  mergedVideoPath;
    if ([SRUtils sr_exist:myPathDocs]) {
        [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    [exporter setVideoComposition:MainCompositionInst];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self exportDidFinish:exporter];
         });
     }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session
{
	NSURL *outputURL = session.outputURL;
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL
									completionBlock:^(NSURL *assetURL, NSError *error){
                                        NSLog(@"asset URL : %@   error: %@", assetURL, error);
                                        dispatch_async(dispatch_get_main_queue(), ^{
											if (error) {
												NSLog(@"writeVideoToAssestsLibrary failed: %@", error);
											}else{
                                                NSLog(@"Writing3");
                                            }
											
										});
										
									}];
	}
}
#pragma mark Delegates (CRUIWindow)

- (void)_onEvent:(NSNotification *)notification {
  UIEvent *event = [notification object];
  if ([_videoWriter isRecording]) {
    //[_eventRecorder recordEvent:event];
    [_videoWriter setEvent:event];
  }
}

@end
