//
//  SDENewPhotoDetector.h
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SDEPhotoFileFilterAddedPhotosKey;
extern NSString *const SDEPhotoFileFilterDeletedPhotosKey;
extern NSString *const SDEPhotoFileFilterRestoredPhotosKey;

@interface SDEPhotoFileFilter : NSObject

@property (nonatomic) BOOL photoAdded;

+ (SDEPhotoFileFilter *)sharedPhotoFileFilter;
- (void)checkPhotoLibrary;
- (BOOL)isPhotoAdded;
- (void)reset;
- (NSArray *)assetsNeedToScan; //include asset, not url string
- (NSArray *)deletedAssetsURLStringArray;
- (NSArray *)restoredAssetsURLStringArray;
@end
