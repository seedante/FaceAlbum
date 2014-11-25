//
//  Face.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "Face.h"

@implementation Face

@dynamic avatorImage;
@dynamic pathForBackup;
@dynamic detectedFaceImage;
@dynamic detectedFaceRect;
@dynamic faceID;
@dynamic order;
@dynamic section;
@dynamic whetherToDisplay;
@dynamic posterURLString;
@dynamic tag;
@dynamic isMyStar;
@dynamic assetURLString;
@dynamic name;
@dynamic uploaded;
@dynamic accepted;
@dynamic personOwner;
@dynamic photoOwner;

+ (NSString *)entityName
{
    return @"Face";
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:moc];
}

@end
