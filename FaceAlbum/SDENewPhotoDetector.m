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

@property (nonatomic, readwrite) NSMutableArray *newAssets;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) ALAssetsLibrary *photoLibrary;

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

- (void)startDetect
{
    NSMutableSet *allAssets;
    NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        if (group && *stop != YES) {
            //NSURL *groupURL = (NSURL *)[group valueForProperty:ALAssetsGroupPropertyURL];
            NSLog(@"Group: %@", [group valueForProperty:ALAssetsGroupPropertyName]);
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                [allAssets addObject:[assetURL absoluteString]];
            }];
        }
    } failureBlock:nil];
    
    NSEntityDescription *photoEntity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *photoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    [photoFetchRequest setResultType:NSDictionaryResultType];
    NSPropertyDescription *URLStringDescription = [[photoEntity propertiesByName] objectForKey:@"uniqueURLString"];
    NSPropertyDescription *identityHashDescription = [[photoEntity propertiesByName] objectForKey:@"identityHash"];
    [photoFetchRequest setPropertiesToFetch:@[URLStringDescription]];
    //NSArray *kURLResult = [self.managedObjectContext executeFetchRequest:photoFetchRequest error:&error];
    //NSLog(@"URL: %@", kURLResult);
}

- (ALAssetsLibrary *)photoLibrary
{
    if (_photoLibrary != nil) {
        return _photoLibrary;
    }
    _photoLibrary = [[ALAssetsLibrary alloc] init];
    return _photoLibrary;
}


- (NSArray *)newAssetsNeedToScan
{
    return [self.newAssets copy];
}


@end
