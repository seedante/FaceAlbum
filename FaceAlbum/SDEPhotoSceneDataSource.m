//
//  SDEPhotoSceneDataSource.m
//  FaceAlbum
//
//  Created by seedante on 11/19/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPhotoSceneDataSource.h"

@interface SDEPhotoSceneDataSource ()

@end

@implementation SDEPhotoSceneDataSource

+ (SDEPhotoSceneDataSource *)sharedData
{
    static SDEPhotoSceneDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEPhotoSceneDataSource alloc]init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (!self.assetsArray) {
        self.assetsArray = [NSMutableArray new];
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
