//
//  Person.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Face;

@interface Person : NSManagedObject

@property (nonatomic, retain) UIImage * avatorImage;
@property (nonatomic, retain) NSString *portraitFileString;
@property (nonatomic) int32_t faceCount;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * personID;
@property (nonatomic) int32_t photoCount;
@property (nonatomic) int32_t order;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic, retain) NSSet *ownedFaces;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addOwnedFacesObject:(Face *)value;
- (void)removeOwnedFacesObject:(Face *)value;
- (void)addOwnedFaces:(NSSet *)values;
- (void)removeOwnedFaces:(NSSet *)values;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
