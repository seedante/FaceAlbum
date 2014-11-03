//
//  Photo.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "Photo.h"
#import "AlbumGroup.h"
#import "Face.h"


@implementation Photo

@dynamic thumbnail;
@dynamic isExisted;
@dynamic offlineTime;
@dynamic uniqueURLString;
@dynamic whetherToDisplay;
@dynamic faceCount;
@dynamic faceset;
@dynamic albumOwner;

+ (NSString *)entityName
{
    return @"Photo";
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:moc];
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc Display:(BOOL)whetherToDisplay URLString:(NSString *)URLString
{
    Photo *newPhoto = [self insertNewObjectInManagedObjectContext:moc];
    newPhoto.whetherToDisplay = NO;
    newPhoto.uniqueURLString = URLString;
    newPhoto.isExisted = YES;
    return newPhoto;
}

@end
