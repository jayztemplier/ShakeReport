//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//

#import "SRRecordable.h"
#import <AVFoundation/AVFoundation.h>

/*!
 Recorder for the front facing camera.
 */
@interface SRCameraRecorder : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, SRRecordable> {
  AVCaptureSession *_captureSession;
  AVCaptureVideoDataOutput *_videoOutput;
  AVCaptureAudioDataOutput *_audioOutput;
    
  uint8_t *_data; // Data from camera
  size_t _dataSize;
  size_t _width;
  size_t _height;
  size_t _bytesPerRow;
  
  CVImageBufferRef _imageBuffer;
  
  dispatch_queue_t _queue;
}

/*!
 The current audio writer (the microphone).
 */
@property (weak) id<SRAudioWriter> audioWriter;

/*!
 The presentation time for the current data buffer.
 */
@property CMTime presentationTime;

@end
