//
//  SDENewPhotoDetector.m
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDENewPhotoDetector.h"
#import "Store.h"
@import AssetsLibrary;

@interface SDENewPhotoDetector ()

@property (nonatomic) NSMutableSet *allAssetsURLString;
@property (nonatomic) NSMutableSet *allNewAssets;
@property (nonatomic) NSMutableSet *existAgainAssetsURLString;
@property (nonatomic) NSSet *deletedAssetsURLString;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) BOOL isThereNewPhoto;

@end

@implementation SDENewPhotoDetector

- (id)init
{
    self = [super init];
    if (self) {
        self.allAssetsURLString = [NSMutableSet new];
        self.allNewAssets = [NSMutableSet new];
        self.existAgainAssetsURLString = [NSMutableSet new];
    }
    return self;
}

+ (SDENewPhotoDetector *)sharedPhotoDetector
{
    static SDENewPhotoDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDENewPhotoDetector alloc] init];
    });
    
    return sharedInstance;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[Store sharedStore] managedObjectContext];
    }
    return _managedObjectContext;
}

- (BOOL)shouldScanPhotoLibrary
{
    return self.isThereNewPhoto;
}

- (void)cleanData
{
    if (self.allNewAssets) {
        [self.allNewAssets removeAllObjects];
    }
    
    if (self.deletedAssetsURLString) {
        self.deletedAssetsURLString = nil;
    }
    
    if (self.existAgainAssetsURLString) {
        [self.existAgainAssetsURLString removeAllObjects];
    }
    
    if (self.isThereNewPhoto) {
        self.isThereNewPhoto = NO;
    }
}

- (ALAssetsLibrary *)photoLibrary
{
    if (_photoLibrary != nil) {
        return _photoLibrary;
    }
    _photoLibrary = [[ALAssetsLibrary alloc] init];
    return _photoLibrary;
}


- (NSArray *)assetsNeedToScan
{
    return [self.allNewAssets allObjects];
}

- (NSArray *)notexistedAssetsURLString
{
    return [self.deletedAssetsURLString allObjects];
}

- (NSArray *)againStoredAssetsURLString
{
    return [self.existAgainAssetsURLString allObjects];
}

- (void)comparePhotoDataBetweenLocalAndDataBase
{
    
    if (!self.allNewAssets) {
        self.allNewAssets = [NSMutableSet new];
    }else{
        [self.allNewAssets removeAllObjects];
    }
    
    if (self.deletedAssetsURLString) {
        self.deletedAssetsURLString = nil;
    }
    
    NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        if (group && *stop != YES) {
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                if (asset && *shouldStop != YES) {
                    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                    [self.allAssetsURLString addObject:[assetURL absoluteString]];
                }
            }];
        }else{
            //DLog(@"All Assets Count: %d", self.allAssetsURLString.count);
            [self performSelector:@selector(continueToCompare) withObject:nil afterDelay:0.1];
        }
    } failureBlock:nil];
    
}

- (void)continueToCompare
{
    NSMutableSet *scanedAssets = [NSMutableSet new];
    NSEntityDescription *photoEntity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *photoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    [photoFetchRequest setResultType:NSDictionaryResultType];
    NSPropertyDescription *URLStringDescription = [[photoEntity propertiesByName] objectForKey:@"uniqueURLString"];
    NSPropertyDescription *isExistedDescription = [[photoEntity propertiesByName] objectForKey:@"isExisted"];
    [photoFetchRequest setPropertiesToFetch:@[URLStringDescription, isExistedDescription]];
    NSArray *kURLStringResults = [self.managedObjectContext executeFetchRequest:photoFetchRequest error:nil];
    for (NSDictionary *result in kURLStringResults) {
        if([result[@"isExisted"] boolValue]){
            [scanedAssets addObject:result[@"uniqueURLString"]];
        }else
            [self.existAgainAssetsURLString addObject:result[@"uniqueURLString"]];
    }
    DLog(@"All Assets Count: %lu", (unsigned long)self.allAssetsURLString.count);
    DLog(@"Scaned Assets Count: %lu", (unsigned long)(scanedAssets.count + self.existAgainAssetsURLString.count));
    NSSet *allAssetsCopy = [self.allAssetsURLString copy];
    if (self.existAgainAssetsURLString.count > 0) {
        if ([allAssetsCopy intersectsSet:self.existAgainAssetsURLString]) {
            [self.existAgainAssetsURLString intersectSet:self.allAssetsURLString];
            if (self.existAgainAssetsURLString.count > 0) {
                DLog(@"%lu assets go back", (unsigned long)self.existAgainAssetsURLString.count);
            }
        }
    }
    
    [self.allAssetsURLString minusSet:scanedAssets];
    if (self.allAssetsURLString.count > 0) {
        self.isThereNewPhoto = YES;
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        for (NSString *URLString in self.allAssetsURLString) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.photoLibrary assetForURL:[NSURL URLWithString:URLString] resultBlock:^(ALAsset *asset){
                    [self.allNewAssets addObject:asset];
                    dispatch_semaphore_signal(sema);
                }failureBlock:nil];
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        DLog(@"New Photo count: %lu", (unsigned long)self.allNewAssets.count);
    }else{
        self.isThereNewPhoto = NO;
        self.allNewAssets = nil;
    }
    [scanedAssets minusSet:allAssetsCopy];
    if (scanedAssets.count > 0) {
        self.deletedAssetsURLString = [scanedAssets copy];
        DLog(@"There are %lu photo is deleted from local device.", (unsigned long)scanedAssets.count);
    }else
        self.deletedAssetsURLString = nil;
}

@end
