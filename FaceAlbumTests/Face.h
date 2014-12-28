//
//  Face.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class Photo;
@class Person;


@interface Face : NSManagedObject

@property (nonatomic, retain) UIImage * avatorImage;
@property (nonatomic, retain) NSString * storeFileName;
@property (nonatomic, retain) NSValue * portraitAreaRect;
@property (nonatomic, retain) NSString * faceID;
@property (nonatomic) double order;
@property (nonatomic) int32_t section;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic, retain) NSString * tag;
@property (nonatomic) BOOL isMyStar;
@property (nonatomic) NSString *assetURLString;
@property (nonatomic) NSString *name;
@property (nonatomic) BOOL uploaded;
@property (nonatomic) BOOL accepted;
@property (nonatomic, retain) Person *personOwner;
@property (nonatomic, retain) Photo *photoOwner;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
