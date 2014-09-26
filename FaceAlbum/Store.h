//
//  Store.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Person;

@interface Store : NSObject

@property (nonatomic, readonly)NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *personFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *photoFetchedResultsController;
@property (nonatomic, readonly) Person *FacelessMan;

+ (Store *)sharedStore;
- (void)setupStoreWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL;

@end
