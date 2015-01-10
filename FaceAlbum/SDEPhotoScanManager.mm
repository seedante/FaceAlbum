//
//  PhotoScanManager.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPhotoScanManager.h"
#import "APIKey+APISecret.h"
#import "FaceppLocalDetector.h"
#import "SDEStore.h"
#import "Photo.h"
#import "Face.h"
#import "AlbumGroup.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

static CGFloat const avatorWidth = 150.0f;
static CGFloat const avatorHeight = 150.0f;

CGImageRef (^flipCGImage)(CGImageRef sourceCGImage) = ^CGImageRef(CGImageRef sourceCGImage){
    CGSize size = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), sourceCGImage);
    CGImageRef result = [UIGraphicsGetImageFromCurrentImageContext() CGImage];
    UIGraphicsEndImageContext();
    return result;
};

UIImage *(^UIImageConvertedFromCGImage)(CGImageRef sourceCGImage) = ^UIImage *(CGImageRef sourceCGImage){
    CGSize size = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), flipCGImage(sourceCGImage));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
};

UIImage *(^UIImageFromCGImageWithNewsize)(CGImageRef sourceCGImage, CGSize targetSize) = ^UIImage *(CGImageRef sourceCGImage, CGSize targetSize){
    CGRect targetRect = CGRectMake(0.0, 0.0, targetSize.width, targetSize.height);
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, targetRect, flipCGImage(sourceCGImage));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
};

CGRect (^CGRectAvatorBound)(CGSize imageSize, CGRect faceBound) = ^CGRect(CGSize imageSize, CGRect faceBound){
    CGRect headBound;
    float x = faceBound.origin.x - 0.6*faceBound.size.width;
    float y = faceBound.origin.y - 0.85*faceBound.size.height;
    headBound.origin.x = x > 0.0?x:0.0;
    headBound.origin.y = y > 0.0?y:0.0;
    
    float width = faceBound.size.width * 2.2;
    float height = faceBound.size.height * 2.2;
    if (width + x > imageSize.width) {
        width = imageSize.width - x;
    }
    headBound.size.width = width;
    if (height + y > imageSize.height) {
        height = imageSize.height - y;
    }
    headBound.size.height = height;
    
    return headBound;
};

CGRect (^CGRectPortraitBound)(CGSize imageSize, CGRect faceBound) = ^CGRect(CGSize imageSize, CGRect faceBound){
    CGRect headBound;
    float x = faceBound.origin.x - faceBound.size.width;
    float y = faceBound.origin.y - faceBound.size.height;
    headBound.origin.x = x > 0.0?x:0.0;
    headBound.origin.y = y > 0.0?y:0.0;
    
    float width = faceBound.size.width * 3.0;
    float height = faceBound.size.height * 4.0;
    if (width + x > imageSize.width) {
        width = imageSize.width - x;
    }
    headBound.size.width = width;
    if (height + y > imageSize.height) {
        height = imageSize.height - y;
    }
    headBound.size.height = height;
    
    return headBound;
};

@interface SDEPhotoScanManager ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) FaceppLocalDetector *localFaceppDetector;
@property (nonatomic) CIDetector *appleImageDetector;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSMutableArray *facesInAPhoto;
@property (nonatomic) NSString *cachePath;

@end


@implementation SDEPhotoScanManager

+ (SDEPhotoScanManager *)sharedPhotoScanManager
{
    static SDEPhotoScanManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEPhotoScanManager alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        _numberOfItemsInFirstSection = 0;
        _faceCountInThisScan = 0;
        _saveFlag = 0;
    }
    return self;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    _managedObjectContext = [[SDEStore sharedStore] managedObjectContext];
    return _managedObjectContext;
}

- (ALAssetsLibrary *)photoLibrary
{
    if (_photoLibrary != nil) {
        return _photoLibrary;
    }
    _photoLibrary = [[ALAssetsLibrary alloc] init];
    return _photoLibrary;
}

- (FaceppLocalDetector *)localFaceppDetector
{
    if (_localFaceppDetector != nil) {
        return _localFaceppDetector;
    }
    
    NSArray *keys = @[FaceppDetectorTracking, FaceppDetectorMinFaceSize, FaceppDetectorAccuracy];
    NSArray *values = @[@NO, @20, FaceppDetectorAccuracyHigh];
    NSDictionary *options = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    _localFaceppDetector = [FaceppLocalDetector detectorOfOptions:options andAPIKey:_API_KEY];
    return _localFaceppDetector;
}

- (NSMutableArray *)facesInAPhoto
{ 
    if (_facesInAPhoto != nil) {
        return _facesInAPhoto;
    }
    _facesInAPhoto = [[NSMutableArray alloc] init];
    return _facesInAPhoto;
}

- (void)saveAfterScan
{
    NSLog(@"Save Data.");
    NSError *error;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Scan Finish and Save Error: %@", error);
    }
    //[self.managedObjectContext reset];
}

- (NSArray *)allAvatorsInPhoto
{
    return [self.facesInAPhoto copy];
}

- (void)cleanCache
{
    if (self.facesInAPhoto.count > 0) {
        [self.facesInAPhoto removeAllObjects];
    }
}

- (NSString *)cachePath
{
    if (!_cachePath) {
        _cachePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    }

    return _cachePath;
}

#pragma mark - Scan Method Family

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


- (BOOL)scanAsset:(ALAsset *)asset withDetector:(FaceDetectorType)detectorType
{
    BOOL includeFace = NO;
    if (self.facesInAPhoto.count > 0) {
        [self.facesInAPhoto removeAllObjects];
    }
    //NSLog(@"Current Avator count for facelessman: %lu", (unsigned long)self.numberOfItemsInFirstSection);
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    CGImageRef sourceCGImage = [assetRepresentation fullScreenImage];
    //CGImageRef sourceCGImage = asset.aspectRatioThumbnail;
    UIImage *imageForDetect = [UIImage imageWithCGImage:sourceCGImage];
    
    Photo *newPhoto = [Photo insertNewObjectInManagedObjectContext:self.managedObjectContext];
    newPhoto.uniqueURLString = [(NSURL *)[asset valueForProperty:ALAssetPropertyAssetURL] absoluteString];
    newPhoto.isExisted = YES;
    
    //NSLog(@"Scan Photo: %@", [asset valueForProperty:ALAssetPropertyAssetURL]);
    FaceppLocalResult *detectResult = [self.localFaceppDetector detectWithImage:imageForDetect];
    if (detectResult.faces.count > 0) {
        includeFace = YES;
        CGSize imageSize = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
        //NSLog(@"Detect %lu faces in the Photo.", (unsigned long)detectResult.faces.count);
        self.faceCountInThisScan += detectResult.faces.count;
        for (FaceppLocalFace *detectedFace in detectResult.faces) {
            Face *newFace = [Face insertNewObjectInManagedObjectContext:self.managedObjectContext];
            newFace.whetherToDisplay = YES;
            newFace.isMyStar = NO;
            newFace.section = 0;
            newFace.photoOwner = newPhoto;
            newFace.assetURLString = newPhoto.uniqueURLString;
            //newFace.name = @"";
            
            CGRect avatorBound = CGRectAvatorBound(imageSize, detectedFace.bounds);
            CGImageRef avatorCGImage = CGImageCreateWithImageInRect(sourceCGImage, avatorBound);
            UIImage *avatorUIImage = nil;
            if (MAX(detectedFace.bounds.size.width, detectedFace.bounds.size.height) > 100.0f) {
                avatorUIImage = UIImageFromCGImageWithNewsize(avatorCGImage, CGSizeMake(avatorWidth, avatorHeight));
            }else
                avatorUIImage = [UIImage imageWithCGImage:avatorCGImage];
            [self.facesInAPhoto addObject:avatorUIImage];
            
            newFace.avatorImage = avatorUIImage;
            NSString *avatorName = [[[NSUUID alloc] init] UUIDString];
            avatorName = [avatorName stringByAppendingPathExtension:@"jpg"];
            newFace.storeFileName = avatorName;
            NSString *avatorPath = [self.cachePath stringByAppendingPathComponent:avatorName];
            NSData *avatorImageData = UIImageJPEGRepresentation(avatorUIImage, 1.0f);
            BOOL writeSuccess = [avatorImageData writeToFile:avatorPath atomically:YES];
            if (!writeSuccess)
                NSLog(@"Write Avator Image To File Error");
            CGImageRelease(avatorCGImage);
            
            CGRect portraitBound = CGRectPortraitBound(imageSize, detectedFace.bounds);
            newFace.portraitAreaRect = [NSValue valueWithCGRect:portraitBound];
            /*
            CGRect portraitBound = PortraitBound(imageSize, detectedFace.bounds);
            CGImageRef portraitCGImage = CGImageCreateWithImageInRect(sourceCGImage, portraitBound);
            UIImage *posterImage = [UIImage imageWithCGImage:portraitCGImage];
            NSString *posterName = [[[NSUUID alloc] init] UUIDString];
            posterName = [posterName stringByAppendingPathExtension:@"jpg"];
            newFace.posterURLString = posterName;
            NSString *savePath = [self.cachePath stringByAppendingPathComponent:posterName];
            NSData *imageData = UIImageJPEGRepresentation(posterImage, 1.0);
            BOOL success = [imageData writeToFile:savePath atomically:YES];
            if (!success)
                NSLog(@"Write Poster Image to File Error!");
            CGImageRelease(portraitCGImage);
             */

            self.numberOfItemsInFirstSection += 1;
            newFace.order = self.numberOfItemsInFirstSection;
            
        }
        newPhoto.faceCount = (int32_t)detectResult.faces.count;
        newPhoto.whetherToDisplay = YES;
    }else{
        newPhoto.faceCount = 0;
        newPhoto.whetherToDisplay = NO;
    }
    
    //CGImageRelease(sourceCGImage);
    self.saveFlag += 1;
    if (self.saveFlag == 10) {
        [self saveAfterScan];
        self.saveFlag = 0;
    }
    return includeFace;
}

- (BOOL)updateAsset:(ALAsset *)asset WithDetector:(FaceDetectorType)detectorType
{
    return YES;
}

@end
