//
//  Face.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Face : NSManagedObject

@property (nonatomic, retain) UIImage * avatorImage;
@property (nonatomic, retain) NSString * pathForBackup;
@property (nonatomic, retain) UIImage * detectedFaceImage;
@property (nonatomic, retain) NSValue * detectedFaceRect;
@property (nonatomic, retain) NSString * faceID;
@property (nonatomic) double order;
@property (nonatomic) int32_t section;
@property (nonatomic) BOOL whetherToDisplay;
@property (nonatomic, retain) UIImage * posterImage;
@property (nonatomic, retain) NSString * tag;
@property (nonatomic) BOOL isMyStar;
@property (nonatomic, retain) NSManagedObject *personOwner;
@property (nonatomic, retain) NSManagedObject *photoOwner;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
