//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//
// Original Source from AFNetworking 1.x

#import <Foundation/Foundation.h>
#import <Availability.h>

typedef enum {
    SRSSLPinningModeNone,
    SRSSLPinningModePublicKey,
    SRSSLPinningModeCertificate,
} SRURLConnectionOperationSSLPinningMode;


#ifndef __UTTYPE__
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#pragma message("MobileCoreServices framework not found in project, or not included in precompiled header. Automatic MIME type detection when uploading files in multipart requests will not be available.")
#else
#pragma message("CoreServices framework not found in project, or not included in precompiled header. Automatic MIME type detection when uploading files in multipart requests will not be available.")
#endif
#endif

typedef enum {
    SRFormURLParameterEncoding,
    SRJSONParameterEncoding,
    SRPropertyListParameterEncoding,
} SRHTTPClientParameterEncoding;

@class SRHTTPRequestOperation;
@protocol SRMultipartFormData;

@interface SRHTTPClient : NSObject <NSCoding, NSCopying>


@property (readonly, nonatomic, strong) NSURL *baseURL;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, assign) SRHTTPClientParameterEncoding parameterEncoding;
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) SRURLConnectionOperationSSLPinningMode defaultSSLPinningMode;
@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;
+ (instancetype)clientWithBaseURL:(NSURL *)url;
- (id)initWithBaseURL:(NSURL *)url;
- (void)unregisterHTTPOperationClass:(Class)operationClass;
- (NSString *)defaultValueForHeader:(NSString *)header;
- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value;
- (void)setAuthorizationHeaderWithUsername:(NSString *)username
                                  password:(NSString *)password;
- (void)setAuthorizationHeaderWithToken:(NSString *)token;
- (void)clearAuthorizationHeader;
- (void)setDefaultCredential:(NSURLCredential *)credential;
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <SRMultipartFormData> formData))block;
@end

extern NSString * SRQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding encoding);

#pragma mark -

extern NSUInteger const kSRUploadStream3GSuggestedPacketSize;
extern NSTimeInterval const kSRUploadStream3GSuggestedDelay;

@protocol SRMultipartFormData

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error;
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error;
- (void)appendPartWithInputStream:(NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(unsigned long long)length
                         mimeType:(NSString *)mimeType;
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;
- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body;

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end
