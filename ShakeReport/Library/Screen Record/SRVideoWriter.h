//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


#import "SRDefines.h"
#import "SRRecordable.h"
#import "SRCameraRecorder.h"
#import "SRVideo.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/*!
 Video writer records a video from a list of recordables.
 */
@interface SRVideoWriter : NSObject <SRAudioWriter> {
  AVAssetWriter *_writer;
  AVAssetWriterInput *_writerInput;
  AVAssetWriterInputPixelBufferAdaptor *_bufferAdapter;
  
  CVPixelBufferRef _pixelBuffer;
  
  AVAssetWriterInput *_audioWriterInput;
  
  dispatch_source_t _timer;
  
  CRRecorderOptions _options;
  
  NSTimeInterval _startTime;
  CMTime _previousPresentationTime;
  BOOL _started;
  
  SRCameraRecorder *_userRecorder;
  NSMutableArray *_recordables;
  CGSize _videoSize;
  
  size_t _bytesPerRow;
  uint8_t *_data;
  
  NSUInteger _fps;
  NSTimeInterval _fpsTimeStart;
  
  NSMutableArray *_touches;
}

@property (readonly, strong) SRVideo *video;

/*!
 The size of the drawn touch circle.
 Defaults to 40, 40.
 */
@property CGSize touchSize;

/*!
 The color of the touch circle.
 Defaults to (255,0,0,0.5).
 */
@property (strong) UIColor *touchColor;

/*!
 How long the touch circle lingers, in seconds.
 Defaults to 0.7 seconds.
 */
@property NSTimeInterval touchInterval;


/*!
 Create video writer with recordables.
 @param recordable Recordable
 @param options Options
 */
- (id)initWithRecordable:(id<SRRecordable>)recordable options:(CRRecorderOptions)options;

/*!
 Start the video writer.
 @param error Out error
 @result YES if started succesfully, NO otherwise
 */
- (BOOL)start:(NSError **)error;

/*!
 @result YES if recording, NO otherwise
 */
- (BOOL)isRecording;

/*!
 Stop the video writer.
 @param error Out error
 */
- (BOOL)stop:(NSError **)error;

/*!
 Set event.
 @param event Event
 */
- (void)setEvent:(UIEvent *)event;

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

@end
