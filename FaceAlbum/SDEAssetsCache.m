//
//  SDEPhotoSceneDataSource.m
//  FaceAlbum
//
//  Created by seedante on 11/19/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEAssetsCache.h"

@interface SDEAssetsCache ()

@end

@implementation SDEAssetsCache

+ (SDEAssetsCache *)sharedData
{
    static SDEAssetsCache *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEAssetsCache alloc]init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (!self.assetsDictionary) {
        self.assetsDictionary = [NSMutableDictionary new];
    }
    
    if (!self.albumsArray) {
        self.albumsArray = [NSMutableArray new];
    }
    
    if (!self.timelineDictionary) {
        self.timelineDictionary = [NSMutableDictionary new];
    }
    
    if (!self.timeHeaderArray) {
        self.timeHeaderArray = [NSMutableArray new];
    }
    
    return self;
}

@end
