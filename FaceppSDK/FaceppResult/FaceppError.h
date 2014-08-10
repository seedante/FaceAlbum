//
//  FaceppError.h
//  ImageCapture
//
//  Created by youmu on 12-11-27.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FaceppError : NSObject

/*!
 *  @brief http status code
 */
@property int httpStatusCode;

/*!
 *  @brief error code which defined by FacePlusPlus
 */
@property int errorCode;

/*!
 *  @brief error message
 */
@property (nonatomic, retain) NSString* message;


-(id) initWithErrorMsg:(NSString*) msg andHttpStatusCode:(NSInteger)httpCode andErrorCode:(int) code;
+(id) errorWithErrorMsg:(NSString*) msg andHttpStatusCode:(NSInteger)httpCode andErrorCode:(int) code;
+(id) checkErrorFromJSONDictionary:(NSDictionary*) dict andHttpStatusCode:(NSInteger)httpCode;

@end
