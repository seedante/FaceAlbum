//
//  PhotoScanManager.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class FaceppLocalDetector;

typedef enum : NSUInteger {
    FaceppFaceDetector = 0,
    AppleFaceDetector
} FaceDetectorType;

@interface PhotoScanManager : NSObject

@property (nonatomic) NSUInteger numberOfItemsInFirstSection;
@property (nonatomic) NSUInteger faceCountInThisScan;
@property (nonatomic) NSUInteger saveFlag;

+ (PhotoScanManager *)sharedPhotoScanManager;
- (BOOL)scanAsset:(ALAsset *)asset withDetector: (FaceDetectorType)detectorType;
- (BOOL)updateAsset:(ALAsset *)asset WithDetector:(FaceDetectorType)detectorType;
- (NSArray *)allAvatorsInPhoto;
- (void)cleanCache;
- (void)saveAfterScan;

@end
