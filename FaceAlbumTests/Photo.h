//
//  Photo.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumGroup, Face;

@interface Photo : NSManagedObject

@property (nonatomic) UIImage *thumbnail;
@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) BOOL isExisted;
@property (nonatomic) NSTimeInterval offlineTime;
@property (nonatomic, retain) NSString * uniqueURLString;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic) int32_t faceCount;
@property (nonatomic, retain) NSSet *faceset;
@property (nonatomic, retain) AlbumGroup *albumOwner;
@end

@interface Photo (CoreDataGeneratedAccessors)

- (void)addFacesetObject:(Face *)value;
- (void)removeFacesetObject:(Face *)value;
- (void)addFaceset:(NSSet *)values;
- (void)removeFaceset:(NSSet *)values;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc Display:(BOOL)whetherToDisplay  URLString:(NSString *)URLString;

@end
