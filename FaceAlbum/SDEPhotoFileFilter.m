//
//  SDENewPhotoDetector.m
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPhotoFileFilter.h"
#import "Store.h"
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
        _managedObjectContext = [[Store sharedStore] managedObjectContext];
    }
    return _managedObjectContext;
}

- (BOOL)isPhotoAdded
{
    return self.photoAdded;
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
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(defaultQueue, ^{
        NSLog(@"check photo file.");
        if (!self.addedAssetsSet) {
            self.addedAssetsSet = [NSMutableSet new];
        }else{
            [self.addedAssetsSet removeAllObjects];
        }
        
        if (!self.allAssetsDictionary) {
            self.allAssetsDictionary = [NSMutableDictionary new];
        }else
            [self.allAssetsDictionary removeAllObjects];
        
        if (self.deletedAssetsURLStringSet) {
            self.deletedAssetsURLStringSet = nil;
        }
        
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
                NSLog(@"All Assets Count: %lu", (unsigned long)self.allAssetsURLStringSet.count);
                [self continueToCompare];
            }
        } failureBlock:nil];
    });

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
    NSLog(@"Scaned Assets Count: %lu", (unsigned long)kURLStringResults.count);
    NSSet *allAssetsCopy = [self.allAssetsURLStringSet copy];
    [scanedAssetsURLStringSet minusSet:allAssetsCopy];
    if (scanedAssetsURLStringSet.count > 0) {
        self.deletedAssetsURLStringSet = [scanedAssetsURLStringSet copy];
        NSLog(@"There are %lu photos deleted from local device.", (unsigned long)scanedAssetsURLStringSet.count);
    }else
        self.deletedAssetsURLStringSet = [NSSet set];
    
    if (self.restoredAssetsURLStringSet.count > 0) {
        NSSet *restoredAssetsCopy = [self.restoredAssetsURLStringSet copy];
        if ([allAssetsCopy intersectsSet:restoredAssetsCopy]) {
            [self.restoredAssetsURLStringSet intersectSet:self.allAssetsURLStringSet];
            if (self.restoredAssetsURLStringSet.count > 0) {
                NSLog(@"%lu assets go back", (unsigned long)self.restoredAssetsURLStringSet.count);
            }
        }
    }
    
    [self.allAssetsURLStringSet minusSet:self.restoredAssetsURLStringSet];
    [self.allAssetsURLStringSet minusSet:scanedAssetsURLStringSet];
    if (self.allAssetsURLStringSet.count > 0) {
        for (NSString *assetURLString in self.allAssetsURLStringSet) {
            ALAsset *asset = self.allAssetsDictionary[assetURLString];
            [self.addedAssetsSet addObject:asset];
        }
        [self.allAssetsDictionary removeAllObjects];
        
        NSLog(@"New Photo count: %lu", (unsigned long)self.addedAssetsSet.count);
        self.photoAdded = YES;
        /*
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        for (NSString *URLString in self.allAssetsURLStringSet) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.photoLibrary assetForURL:[NSURL URLWithString:URLString] resultBlock:^(ALAsset *asset){
                    [self.addedAssetsSet addObject:asset];
                    dispatch_semaphore_signal(sema);
                }failureBlock:nil];
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
         */
        
    }else{
        self.photoAdded = NO;
        [self.addedAssetsSet removeAllObjects];
    }

}

@end
