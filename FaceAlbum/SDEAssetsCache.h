//
//  SDEPhotoSceneDataSource.h
//  FaceAlbum
//
//  Created by seedante on 11/19/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDEAssetsCache : NSObject

@property (nonatomic) NSMutableDictionary *assetsDictionary;
@property (nonatomic) NSMutableArray *albumsArray;
@property (nonatomic) NSMutableDictionary *timelineDictionary;
@property (nonatomic) NSMutableArray *timeHeaderArray;

+ (SDEAssetsCache *)sharedData;

@end
