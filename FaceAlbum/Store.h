//
//  Store.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Store : NSObject

@property (nonatomic, readonly)NSManagedObjectContext *managedObjectContext;


+ (Store *)sharedStore;
- (void)setupStoreWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL;

@end
