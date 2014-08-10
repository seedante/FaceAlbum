//
//  PhotoScanManager.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "PhotoScanManager.h"
#import "APIKey+APISecret.h"
#import "FaceppLocalDetector.h"
#import "Store.h"
#import "Photo.h"
#import "Face.h"
#import "AlbumGroup.h"
#import <QuartzCore/QuartzCore.h>

#define avatorSize 100.0

CGImageRef (^flipCGImage)(CGImageRef sourceCGImage) = ^CGImageRef(CGImageRef sourceCGImage){
    CGSize size = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), sourceCGImage);
    CGImageRef result = [UIGraphicsGetImageFromCurrentImageContext() CGImage];
    UIGraphicsEndImageContext();
    return result;
};

UIImage *(^CGImageToUIImage)(CGImageRef sourceCGImage) = ^UIImage *(CGImageRef sourceCGImage){
    CGSize size = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), flipCGImage(sourceCGImage));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
};

UIImage *(^resizeToCGSize)(CGImageRef sourceCGImage, CGSize targetSize) = ^UIImage *(CGImageRef sourceCGImage, CGSize targetSize){
    CGRect targetRect = CGRectMake(0.0, 0.0, targetSize.width, targetSize.height);
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, targetRect, flipCGImage(sourceCGImage));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
};

CGRect (^HeadBound)(CGSize imageSize, CGRect faceBound) = ^CGRect(CGSize imageSize, CGRect faceBound){
    CGRect headBound;
    float x = faceBound.origin.x - faceBound.size.width*0.5;
    float y = faceBound.origin.y - faceBound.size.height*0.7;
    headBound.origin.x = x > 0.0?x:0.0;
    headBound.origin.y = y > 0.0?y:0.0;
    
    float width = faceBound.size.width * 2.0;
    float height = faceBound.size.height * 2.0;
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


@interface PhotoScanManager ()
{
    __block long currentItemNumberInFirstSection;
}

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) FaceppLocalDetector *localFaceppDetector;
@property (nonatomic) CIDetector *appleImageDetector;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSMutableArray *facesInAPhoto;

@end


@implementation PhotoScanManager

+ (PhotoScanManager *)sharedPhotoScanManager
{
    static PhotoScanManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PhotoScanManager alloc] init];
    });
    
    return sharedInstance;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    _managedObjectContext = [[Store sharedStore] managedObjectContext];
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

- (void)save
{
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"PhotoScanManager Save Error: %@", error);
    }
}

- (NSArray *)allFacesInPhoto
{
    return [self.facesInAPhoto copy];
}

- (void)cleanCache
{
    if (self.facesInAPhoto.count > 0) {
        [self.facesInAPhoto removeAllObjects];
    }
}

- (void)filterAssets
{
    
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
    
    @autoreleasepool {
        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
        CGImageRef sourceCGImage = [assetRepresentation fullScreenImage];
        UIImage *imageForDetect = [UIImage imageWithCGImage:sourceCGImage];
        
        Photo *newPhoto = [Photo insertNewObjectInManagedObjectContext:self.managedObjectContext];
        newPhoto.uniqueURLString = [(NSURL *)[asset valueForProperty:ALAssetPropertyAssetURL] absoluteString];
        newPhoto.isExisted = YES;
        
        NSLog(@"Scan Photo: %@", [asset valueForProperty:ALAssetPropertyAssetURL]);
        FaceppLocalResult *detectResult = [self.localFaceppDetector detectWithImage:imageForDetect];
        if (detectResult.faces.count > 0) {
            includeFace = YES;
            NSLog(@"Detect %lu faces in the Photo", (unsigned long)detectResult.faces.count);
            _faceTotalCount += detectResult.faces.count;
            //NSLog(@"Face Count: %lu For Now.", (unsigned long)_faceTotalCount);
            for (FaceppLocalFace *detectedFace in detectResult.faces) {
                CGSize imageSize = CGSizeMake(CGImageGetWidth(sourceCGImage), CGImageGetHeight(sourceCGImage));
                CGRect headBound = HeadBound(imageSize, detectedFace.bounds);
                CGImageRef headCGImage = CGImageCreateWithImageInRect(sourceCGImage, headBound);
                UIImage *headUIImage = CGImageToUIImage(headCGImage);
                UIImage *avatorUIImage = nil;
                if (MAX(detectedFace.bounds.size.width, detectedFace.bounds.size.height) > 100.0) {
                    avatorUIImage = resizeToCGSize(headCGImage, CGSizeMake(avatorSize, avatorSize));
                }else
                    avatorUIImage = headUIImage;
                CGImageRelease(headCGImage);
                [self.facesInAPhoto addObject:avatorUIImage];
                
                currentItemNumberInFirstSection += 1;
                //NSLog(@"Find New Face.");
                Face *newFace = [Face insertNewObjectInManagedObjectContext:self.managedObjectContext];
                newFace.avatorImage = avatorUIImage;
                newFace.posterImage = headUIImage;
                newFace.whetherToDisplay = YES;
                newFace.isMyStar = NO;
                newFace.order = currentItemNumberInFirstSection;
                newFace.section = 0;
                newFace.photoOwner = newPhoto;
            }
            newPhoto.faceCount = detectResult.faces.count;
            newPhoto.whetherToDisplay = YES;
        }else{
            newPhoto.faceCount = 0;
            newPhoto.whetherToDisplay = NO;
        }
    }
    return includeFace;
}

- (BOOL)updateAsset:(ALAsset *)asset WithDetector:(FaceDetectorType)detectorType
{
    return YES;
}

@end
