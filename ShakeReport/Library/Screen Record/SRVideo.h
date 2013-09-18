//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SRDefines.h"

typedef enum {
  SRVideoStatusNone = 0,
  SRVideoStatusStarted,
  SRVideoStatusStopped,
  SRVideoStatusSaving,
  SRVideoStatusSaved,
  SRVideoStatusDiscarded,
} SRVideoStatus;

/*!
 Video.
 */
@interface SRVideo : NSObject

@property (readonly) CMTime presentationTimeStart;
@property (readonly) CMTime presentationTimeStop;
@property (readonly, strong) NSURL *assetURL;
@property (readonly) SRVideoStatus status;

/*!
 Generate a temporary recording file URL.
 @param error Out error
 @result Recording file URL or nil if one couldn't be generated
 */
- (NSURL *)recordingFileURL:(NSError **)error;

/*!
 @result Video presentation time interval in seconds, or -1 if video is recording or never started.
 */
- (NSTimeInterval)timeInterval;

/*!
 Mark video as started.
 @result YES if not already started
 */
- (BOOL)start;

/*!
 Set presentation time start.
 @param presentationTime Start presentation time
 @result YES if started
 */
- (BOOL)startSessionWithPresentationTime:(CMTime)presentationTime;

/*!
 Mark video as stopped.
 @param presentationTime Stop presentation time
 @result YES if not already stopped
 */
- (BOOL)stopWithPresentationTime:(CMTime)presentationTime;

/*!
 Save the video to the album with name.
 If the album doesn't exist, it is created.
 
 The video is also saved to the camera roll.
 
 @param name Album name
 @param resultBlock After successfully saving the video
 @param failureBlock If there is a failure
 */
- (void)saveToAlbumWithName:(NSString *)name resultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock;

/*!
 Discard the video.
 @param error Out error
 @result YES if discarded or didn't exist, NO if there was an error
 */
- (BOOL)discard:(NSError **)error;

/*!
 The shared assets library instance used when saving videos.
 */
+ (ALAssetsLibrary *)sharedAssetsLibrary;

@end
