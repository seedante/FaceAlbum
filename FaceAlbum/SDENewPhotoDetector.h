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
- (void)comparePhotoDataBetweenLocalAndDataBase;
- (BOOL)shouldScanPhotoLibrary;
- (void)cleanData;
- (NSArray *)assetsNeedToScan; //include asset, not url string
- (NSArray *)notexistedAssetsURLString;
@end
