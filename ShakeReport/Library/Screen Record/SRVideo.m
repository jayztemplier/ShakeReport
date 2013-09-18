//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


#import "SRVideo.h"
#import "SRDefines.h"
#import "SRUtils.h"
#import "SRRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface SRVideo ()
@property (readwrite) CMTime presentationTimeStart;
@property (readwrite) CMTime presentationTimeStop;
@property (strong) NSURL *recordingFileURL;
@property (strong) NSURL *assetURL;
@end

@implementation SRVideo

- (id)init {
  if ((self = [super init])) {
    _presentationTimeStart = kCMTimeNegativeInfinity;
    _presentationTimeStop = kCMTimeNegativeInfinity;
  }
  return self;
}

- (NSTimeInterval)timeInterval {
  if (CMTIME_IS_NEGATIVE_INFINITY(_presentationTimeStart)) return -1;
  if (CMTIME_IS_NEGATIVE_INFINITY(_presentationTimeStop)) return -1;
  return (NSTimeInterval)(CMTimeGetSeconds(_presentationTimeStop) - CMTimeGetSeconds(_presentationTimeStart));
}

- (NSURL *)recordingFileURL:(NSError **)error {
    static int videoChunkNumber = 0;
    NSString *filename;
    
    if (!self.recordingFileURL) {
        if (videoChunkNumber) {
            videoChunkNumber--;
            filename = CRFileChunk2;
        } else {
            videoChunkNumber++;
            filename = CRFileChunk1;
        }
        [[SRRecorder sharedRecorder] setLastVideoName:filename];
        NSString *tempFile = [SRUtils sr_temporaryFile:filename deleteIfExists:YES error:error];
        if (!tempFile) {
            CRSetError(error, 0, @"Can't create temp video file.");
            return nil;
        }
        CRDebug(@"File: %@", tempFile);
        self.recordingFileURL = [NSURL fileURLWithPath:tempFile];
    }
    return self.recordingFileURL;
}

- (BOOL)start {
  if (_status != SRVideoStatusNone) return NO;
  [self setStatus:SRVideoStatusStarted];
  return YES;
}

- (BOOL)startSessionWithPresentationTime:(CMTime)presentationTime {
  if (_status != SRVideoStatusStarted) return NO;
  _presentationTimeStart = presentationTime;
  return YES;
}

- (BOOL)stopWithPresentationTime:(CMTime)presentationTime {
  if (_status != SRVideoStatusStarted) return NO;
  _presentationTimeStop = presentationTime;
  [self setStatus:SRVideoStatusStopped];
  return YES;
}

- (void)setStatus:(SRVideoStatus)status {
  _status = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:CRVideoDidChangeNotification object:self];
}

- (void)saveToAlbumWithName:(NSString *)name resultBlock:(CRRecorderSaveResultBlock)resultBlock failureBlock:(CRRecorderSaveFailureBlock)failureBlock {
  if (_status == SRVideoStatusNone) {
    if (failureBlock) failureBlock([SRUtils sr_errorWithDomain:CRErrorDomain code:CRErrorCodeInvalidVideo localizedDescription:@"No recording to save."]);
    return;
  }
  
  if (_status == SRVideoStatusStarted) {
    if (failureBlock) failureBlock([SRUtils sr_errorWithDomain:CRErrorDomain code:CRErrorCodeInvalidState localizedDescription:@"You must stop recording to save the video."]);
    return;
  }
  
  if (_status == SRVideoStatusSaving) {
    if (failureBlock) failureBlock([SRUtils sr_errorWithDomain:CRErrorDomain code:CRErrorCodeInvalidState localizedDescription:@"Video is saving."]);
    return;
  }
  
  if (_status == SRVideoStatusDiscarded) {
    if (failureBlock) failureBlock([SRUtils sr_errorWithDomain:CRErrorDomain code:CRErrorCodeInvalidVideo localizedDescription:@"Video has been discarded."]);
    return;
  }
  
  self.assetURL = nil;
  [self setStatus:SRVideoStatusSaving];
  
  ALAssetsLibrary *library = [SRVideo sharedAssetsLibrary];
  
  [library writeVideoAtPathToSavedPhotosAlbum:self.recordingFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
    if (error) {
      [self setStatus:SRVideoStatusStopped];
      if (failureBlock) failureBlock(error);
      return;
    }
    self.assetURL = assetURL;
    
    if (name) {
      [self _findOrCreateAlbumWithName:name resultBlock:^(ALAssetsGroup *group) {
        [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
          CRDebug(@"Adding asset to group: %@ (editable=%d)", group, group.isEditable);
          if (![group addAsset:asset]) {
            CRWarn(@"Failed to add asset to group");
          }
          CRDebug(@"Saved to album: %@", asset);
          [self setStatus:SRVideoStatusSaved];
          if (resultBlock) resultBlock(assetURL);
        } failureBlock:^(NSError *error) {
          [self setStatus:SRVideoStatusStopped];
          if (failureBlock) failureBlock(error);
        }];
      } failureBlock:^(NSError *error) {
        [self setStatus:SRVideoStatusStopped];
        if (failureBlock) failureBlock(error);
      }];
    } else {
      [self setStatus:SRVideoStatusSaved];
      if (resultBlock) resultBlock(assetURL);
    }
  }];
}

- (BOOL)discard:(NSError **)error {
  if (_status == SRVideoStatusNone) {
    return YES;
  }
  
  if (!self.recordingFileURL) {
    return YES;
  }
  
  if (_status == SRVideoStatusStarted) {
    CRSetError(error, CRErrorCodeInvalidState, @"You must stop recording to save the video.");
    return NO;
  }
  
  if (_status == SRVideoStatusSaving) {
    CRSetError(error, CRErrorCodeInvalidState, @"Video is saving.");
    return NO;
  }
  
  NSString *filePath = [self.recordingFileURL absoluteString];
  BOOL success = YES;
  if ([SRUtils sr_exist:filePath]) {
    success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:error];
  }
  self.recordingFileURL = nil;
  [self setStatus:SRVideoStatusDiscarded];
  return success;
}

+ (ALAssetsLibrary *)sharedAssetsLibrary {
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary *library = nil;
  dispatch_once(&pred, ^{
    library = [[ALAssetsLibrary alloc] init];
  });
  return library;
}

- (void)_findOrCreateAlbumWithName:(NSString *)name resultBlock:(ALAssetsLibraryGroupResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
  
  ALAssetsLibrary *library = [SRVideo sharedAssetsLibrary];
  
  __block BOOL foundAlbum = NO;
  [library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    if ([name compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
      CRDebug(@"Found album: %@ (%@)", name, group);
      foundAlbum = YES;
      *stop = YES;
      if (resultBlock) resultBlock(group);
      return;
    }
    
    // When group is nil its the end of the enumeration
    if (!group && !foundAlbum) {
      CRDebug(@"Creating album: %@", name);
      [library addAssetsGroupAlbumWithName:name resultBlock:resultBlock failureBlock:failureBlock];
    }
  } failureBlock:failureBlock];
}

@end
