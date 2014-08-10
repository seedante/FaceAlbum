//
//  FaceppDetection.m
//  ImageCapture
//
//  Created by youmu on 12-11-26.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import "FaceppDetection.h"
#import "FaceppClient.h"

@implementation FaceppDetection

-(FaceppResult*) detectWithURL:(NSString*)url orImageData:(NSData*) data {
    return [self detectWithURL:url orImageData:data mode:FaceppDetectionModeNormal];
}

-(FaceppResult*) detectWithURL:(NSString*)url orImageData:(NSData*)data mode:(FaceppDetectionMode)mode {
    return [self detectWithURL:url orImageData:data mode:mode attribute:FaceppDetectionAttributeAll];
}

-(FaceppResult*) detectWithURL:(NSString*)url orImageData:(NSData*)data mode:(FaceppDetectionMode)mode attribute:(FaceppDetectionAttribute)attribute {
    return [self detectWithURL:url orImageData:data mode:mode attribute:attribute tag:nil];
}

-(FaceppResult*) detectWithURL:(NSString*)url orImageData:(NSData*)data mode:(FaceppDetectionMode)mode attribute:(FaceppDetectionAttribute)attribute tag:(NSString*)tag {
    return [self detectWithURL:url orImageData:data mode:mode attribute:attribute tag:nil async:NO];
}

-(FaceppResult*) detectWithURL:(NSString*)url orImageData:(NSData*)data mode:(FaceppDetectionMode)mode attribute:(FaceppDetectionAttribute)attribute tag:(NSString*)tag async:(BOOL)async {
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:10];
    if (url != nil) {
        [params addObject:@"url"];
        [params addObject:url];
    }
    if (mode != FaceppDetectionModeNormal) {
        [params addObject:@"mode"];
        [params addObject:@"oneface"];
    }
    if (attribute != FaceppDetectionAttributeAll) {
        [params addObject:@"attribute"];
        [params addObject:@"none"];
    }
    if (tag != nil) {
        [params addObject:@"tag"];
        [params addObject:tag];
    }
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }
    
    // request
    if (data != NULL)
        return [FaceppClient requestWithFunction:@"detection/detect" image:data params:params];
    else
        return [FaceppClient requestWithFunction:@"detection/detect" params:params];
}

-(FaceppResult*) detectWithURL:(NSString *)url orImageData:(NSData *)data mode:(FaceppDetectionMode)mode attribute:(FaceppDetectionAttribute)attribute tag:(NSString *)tag async:(BOOL)async others:(NSArray *)otherParams
{
    NSMutableArray *params = [otherParams mutableCopy];
    if (url != nil) {
        [params addObject:@"url"];
        [params addObject:url];
    }
    if (mode != FaceppDetectionModeNormal) {
        [params addObject:@"mode"];
        [params addObject:@"oneface"];
    }
    if (attribute != FaceppDetectionAttributeAll) {
        [params addObject:@"attribute"];
        [params addObject:@"none"];
    }
    if (tag != nil) {
        [params addObject:@"tag"];
        [params addObject:tag];
    }
    if (async) {
        [params addObject:@"async"];
        [params addObject:@"true"];
    }
    
    if (data != NULL) {
        return [FaceppClient requestWithFunction:@"detection/detect" image:data params:params];
    }else
        return [FaceppClient requestWithFunction:@"detection/detect" params:params];

}

@end
