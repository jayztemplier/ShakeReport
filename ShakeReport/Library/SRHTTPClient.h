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


#ifdef _SYSTEMCONFIGURATION_H
typedef enum {
    SRNetworkReachabilityStatusUnknown          = -1,
    SRNetworkReachabilityStatusNotReachable     = 0,
    SRNetworkReachabilityStatusReachableViaWWAN = 1,
    SRNetworkReachabilityStatusReachableViaWiFi = 2,
} SRNetworkReachabilityStatus;
#else
#pragma message("SystemConfiguration framework not found in project, or not included in precompiled header. Network reachability functionality will not be available.")
#endif

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
#ifdef _SYSTEMCONFIGURATION_H
@property (readonly, nonatomic, assign) SRNetworkReachabilityStatus networkReachabilityStatus;
#endif
@property (nonatomic, assign) SRURLConnectionOperationSSLPinningMode defaultSSLPinningMode;
@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;
+ (instancetype)clientWithBaseURL:(NSURL *)url;
- (id)initWithBaseURL:(NSURL *)url;
#ifdef _SYSTEMCONFIGURATION_H
- (void)setReachabilityStatusChangeBlock:(void (^)(SRNetworkReachabilityStatus status))block;
#endif
- (BOOL)registerHTTPOperationClass:(Class)operationClass;
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
- (SRHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
- (void)enqueueHTTPRequestOperation:(SRHTTPRequestOperation *)operation;
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path;
- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)urlRequests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock;
- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock;
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(SRHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(SRHTTPRequestOperation *operation, NSError *error))failure;
@end

extern NSString * SRQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding encoding);
#ifdef _SYSTEMCONFIGURATION_H
extern NSString * const SRNetworkingReachabilityDidChangeNotification;
extern NSString * const SRNetworkingReachabilityNotificationStatusItem;
#endif

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
