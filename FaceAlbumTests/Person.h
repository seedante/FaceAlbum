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
@property (nonatomic) int32_t faceCount;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * personID;
@property (nonatomic) int32_t photoCount;
@property (nonatomic) int32_t order;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic, retain) NSSet *allFaces;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addAllFacesObject:(Face *)value;
- (void)removeAllFacesObject:(Face *)value;
- (void)addAllFaces:(NSSet *)values;
- (void)removeAllFaces:(NSSet *)values;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
