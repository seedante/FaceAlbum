//
//  AlbumGroup.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AlbumGroup : NSManagedObject

@property (nonatomic) BOOL isExisted;
@property (nonatomic, retain) NSString * persistentID;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic) BOOL whetherToScan;
@property (nonatomic, retain) NSString * uniqueURLString;
@property (nonatomic, retain) NSSet *photoes;
@property (nonatomic) NSNumber *photoCount;
@end

@interface AlbumGroup (CoreDataGeneratedAccessors)

- (void)addPhotoesObject:(NSManagedObject *)value;
- (void)removePhotoesObject:(NSManagedObject *)value;
- (void)addPhotoes:(NSSet *)values;
- (void)removePhotoes:(NSSet *)values;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
