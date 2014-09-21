//
//  SDENewPhotoDetector.h
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDENewPhotoDetector : NSObject

+ (SDENewPhotoDetector *)sharedPhotoDetector;
- (void)startDetect;
- (NSArray *)newAssetsNeedToScan;

@end
