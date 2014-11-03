//
//  PhotoScanManager.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif
@class FaceppLocalDetector;

typedef enum : NSUInteger {
    FaceppFaceDetector = 0,
    AppleFaceDetector
} FaceDetectorType;

@interface PhotoScanManager : NSObject

@property (nonatomic) NSUInteger numberOfItemsInFirstSection;
@property (nonatomic) NSUInteger faceCountInThisScan;

+ (PhotoScanManager *)sharedPhotoScanManager;
- (BOOL)scanAsset:(ALAsset *)asset withDetector: (FaceDetectorType)detectorType;
- (BOOL)updateAsset:(ALAsset *)asset WithDetector:(FaceDetectorType)detectorType;
- (NSArray *)allFacesInPhoto;
- (void)cleanCache;
- (void)filterAssets;
- (void)saveAfterScan;

@end
