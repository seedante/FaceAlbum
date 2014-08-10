//
//  FacePPClient.h
//  ImageCapture
//
//  Created by youmu on 12-10-25.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FaceppResult.h"
#import "FaceppAPI.h"

@interface FaceppClient : NSObject

+(void) setDebugMode:(BOOL)on;
+(void) initializeWithApiKey:(NSString*)apiKey apiSecret:(NSString*)apiSecret region:(APIServerRegion)region;

+(FaceppResult*)requestWithFunction:(NSString*)method params:(NSArray*)params;
+(FaceppResult*)requestWithFunction:(NSString*)method image:(NSData*)imageData params:(NSArray*)params;

@end
