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
@property (nonatomic) NSSet *deletedAssetsURLString;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) BOOL isThereNewPhoto;

@end

@implementation SDENewPhotoDetector

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

- (void)continueToCompare
{
    NSMutableSet *scanedAssets = [NSMutableSet new];
    NSEntityDescription *photoEntity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *photoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    [photoFetchRequest setResultType:NSDictionaryResultType];
    NSPropertyDescription *URLStringDescription = [[photoEntity propertiesByName] objectForKey:@"uniqueURLString"];
    [photoFetchRequest setPropertiesToFetch:@[URLStringDescription]];
    NSArray *kURLStringResults = [self.managedObjectContext executeFetchRequest:photoFetchRequest error:nil];
    for (NSDictionary *result in kURLStringResults) {
        [scanedAssets addObject:result[@"uniqueURLString"]];
    }
    NSLog(@"AllAssets Count: %d", self.allAssetsURLString.count);
    NSLog(@"ScanAssets Count: %d", scanedAssets.count);
    NSSet *allAssetsCopy = [self.allAssetsURLString copy];
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
        NSLog(@"New Photo count: %d", self.allNewAssets.count);
    }else{
        self.isThereNewPhoto = NO;
        self.allNewAssets = nil;
    }
    [scanedAssets minusSet:allAssetsCopy];
    if (scanedAssets.count > 0) {
        self.deletedAssetsURLString = [scanedAssets copy];
    }else
        self.deletedAssetsURLString = nil;
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
    
    self.allAssetsURLString = [[NSMutableSet alloc] init];
    NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        if (group && *stop != YES) {
            //NSURL *groupURL = (NSURL *)[group valueForProperty:ALAssetsGroupPropertyURL];
            NSLog(@"YYYGroup: %@", [group valueForProperty:ALAssetsGroupPropertyName]);
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                if (asset && *shouldStop != YES) {
                    NSLog(@"do some thing");
                    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                    [self.allAssetsURLString addObject:[assetURL absoluteString]];
                }
            }];
        }else{
            [self performSelector:@selector(continueToCompare) withObject:nil afterDelay:0.0];
        }
    } failureBlock:nil];
    
}

- (BOOL)shouldScanPhotoLibrary
{
    return self.isThereNewPhoto;
}

- (void)cleanData
{
    if (self.allNewAssets) {
        self.allNewAssets = nil;
    }
    
    if (self.deletedAssetsURLString) {
        self.deletedAssetsURLString = nil;
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

@end
