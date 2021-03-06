//
//  SDENewPhotoDetector.m
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPhotoFileFilter.h"
#import "SDEStore.h"
@import AssetsLibrary;

NSString *const SDEPhotoFileFilterAddedPhotosKey = @"SDEPhotoAddedKey";
NSString *const SDEPhotoFileFilterDeletedPhotosKey = @"SDEPhotoDeletedKey";
NSString *const SDEPhotoFileFilterRestoredPhotosKey = @"SDEPhotoRestoredKey";

@interface SDEPhotoFileFilter ()

@property (nonatomic) NSMutableSet *allAssetsURLStringSet;
@property (nonatomic) NSMutableSet *addedAssetsSet;
@property (nonatomic) NSMutableSet *restoredAssetsURLStringSet;
@property (nonatomic) NSMutableDictionary *allAssetsDictionary;
@property (nonatomic) NSSet *deletedAssetsURLStringSet;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) ALAssetsLibrary *photoLibrary;


@end

@implementation SDEPhotoFileFilter

- (id)init
{
    self = [super init];
    if (self) {
        self.allAssetsURLStringSet = [NSMutableSet new];
        self.addedAssetsSet = [NSMutableSet new];
        self.restoredAssetsURLStringSet = [NSMutableSet new];
        self.allAssetsDictionary = [NSMutableDictionary new];
        self.executing = NO;
        self.photoAdded = NO;
    }
    return self;
}

+ (SDEPhotoFileFilter *)sharedPhotoFileFilter
{
    static SDEPhotoFileFilter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEPhotoFileFilter alloc] init];
    });
    
    return sharedInstance;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[SDEStore sharedStore] managedObjectContext];
    }
    return _managedObjectContext;
}

- (void)reset
{
    [self.allAssetsDictionary removeAllObjects];
    [self.addedAssetsSet removeAllObjects];
    [self.allAssetsURLStringSet removeAllObjects];
    self.deletedAssetsURLStringSet = nil;
    self.photoAdded = NO;
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
    return [self.addedAssetsSet allObjects];
}

- (NSArray *)deletedAssetsURLStringArray
{
    return [self.deletedAssetsURLStringSet allObjects];
}

- (NSArray *)restoredAssetsURLStringArray
{
    return [self.restoredAssetsURLStringSet allObjects];
}

- (void)checkPhotoLibrary
{
    if ([self isExecuting]) {
        //NSLog(@"Wait for Last call finish");
        return;
    }
    //NSLog(@"check photo file.");
    if (!self.addedAssetsSet) {
        self.addedAssetsSet = [NSMutableSet new];
    }else{
        [self.addedAssetsSet removeAllObjects];
    }
    
    if (!self.restoredAssetsURLStringSet) {
        self.restoredAssetsURLStringSet = [NSMutableSet new];
    }else
        [self.restoredAssetsURLStringSet removeAllObjects];
    
    if (!self.allAssetsDictionary) {
        self.allAssetsDictionary = [NSMutableDictionary new];
    }else
        [self.allAssetsDictionary removeAllObjects];
    
    if (self.deletedAssetsURLStringSet) {
        self.deletedAssetsURLStringSet = nil;
    }
    self.executing = YES;
    
    NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        if (group && *stop != YES) {
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                if (asset && *shouldStop != YES) {
                    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                    NSString *assetURLString = [assetURL absoluteString];
                    [self.allAssetsURLStringSet addObject:assetURLString];
                    [self.allAssetsDictionary setObject:asset forKey:assetURLString];
                }
            }];
        }else{
            //NSLog(@"All Assets Count: %lu", (unsigned long)self.allAssetsURLStringSet.count);
            [self continueToCompare];
            //NSLog(@"Check finish.");
        }
    } failureBlock:nil];
    //本担心太占用 CPU 而使用默认优先级的队列，结果发现虽然扫描一次的速度很快，但是切换到主线程去刷新界面还是太慢了。
    /*
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(defaultQueue, ^{

    });
     */

}

- (void)continueToCompare
{
    NSMutableSet *scanedAssetsURLStringSet = [NSMutableSet new];
    NSEntityDescription *photoEntity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *photoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    [photoFetchRequest setResultType:NSDictionaryResultType];
    NSPropertyDescription *URLStringDescription = [[photoEntity propertiesByName] objectForKey:@"uniqueURLString"];
    NSPropertyDescription *isExistedDescription = [[photoEntity propertiesByName] objectForKey:@"isExisted"];
    [photoFetchRequest setPropertiesToFetch:@[URLStringDescription, isExistedDescription]];
    NSArray *kURLStringResults = [self.managedObjectContext executeFetchRequest:photoFetchRequest error:nil];
    for (NSDictionary *result in kURLStringResults) {
        if([result[@"isExisted"] boolValue]){
            [scanedAssetsURLStringSet addObject:result[@"uniqueURLString"]];
        }else
            [self.restoredAssetsURLStringSet addObject:result[@"uniqueURLString"]];
    }
    //NSLog(@"Scaned Assets Count: %lu", (unsigned long)scanedAssetsURLStringSet.count);
    NSSet *allAssetsCopy = [self.allAssetsURLStringSet copy];
    
    [self.allAssetsURLStringSet minusSet:self.restoredAssetsURLStringSet];
    [self.allAssetsURLStringSet minusSet:scanedAssetsURLStringSet];
    if (self.allAssetsURLStringSet.count > 0) {
        for (NSString *assetURLString in self.allAssetsURLStringSet) {
            ALAsset *asset = self.allAssetsDictionary[assetURLString];
            [self.addedAssetsSet addObject:asset];
        }
        [self.allAssetsDictionary removeAllObjects];
        self.photoAdded = YES;
    }else{
        self.photoAdded = NO;
        [self.addedAssetsSet removeAllObjects];
    }
    
    [scanedAssetsURLStringSet minusSet:allAssetsCopy];
    if (scanedAssetsURLStringSet.count > 0) {
        self.deletedAssetsURLStringSet = [scanedAssetsURLStringSet copy];
        //NSLog(@"There are %lu photos deleted from local device.", (unsigned long)scanedAssetsURLStringSet.count);
    }else
        self.deletedAssetsURLStringSet = [NSSet set];
    
    if (self.restoredAssetsURLStringSet.count > 0) {
        NSSet *restoredAssetsCopy = [self.restoredAssetsURLStringSet copy];
        if ([allAssetsCopy intersectsSet:restoredAssetsCopy]) {
            [self.restoredAssetsURLStringSet intersectSet:self.allAssetsURLStringSet];
        }
    }
    self.executing = NO;
}

@end
