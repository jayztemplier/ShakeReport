//  ShakeReport
//
//  Created by jeremy Templier on 01/06/13.
//  Copyright (c) 2013 Jeremy Templier. All rights reserved.
//


@interface SRUtils : NSObject
+ (NSString *)sr_rot13:(NSString *)str;
+ (BOOL)sr_exist:(NSString *)filePath;
+ (NSString *)sr_temporaryFile:(NSString *)appendPath deleteIfExists:(BOOL)deleteIfExists error:(NSError **)error;
+ (NSError *)sr_errorWithDomain:(NSString *)domain code:(NSInteger)code localizedDescription:(NSString *)localizedDescription;
+ (NSString *)sr_copyTemporaryFile:(NSString *)appendPath toFile:(NSString *)newPath error:(NSError **)error;
+ (NSString *)machine;
@end

void SRDispatch(dispatch_block_t block);
void SRDispatchAfter(NSTimeInterval seconds, dispatch_block_t block);