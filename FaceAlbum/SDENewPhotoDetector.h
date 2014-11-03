//
//  SDENewPhotoDetector.h
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDENewPhotoDetector : NSObject

+ (SDENewPhotoDetector *)sharedPhotoDetector;
- (void)comparePhotoDataBetweenLocalAndDataBase;
- (BOOL)shouldScanPhotoLibrary;
- (void)cleanData;
- (NSArray *)assetsNeedToScan; //include asset, not url string
- (NSArray *)notexistedAssetsURLString;
- (NSArray *)againStoredAssetsURLString;
@end
