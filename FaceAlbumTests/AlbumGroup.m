//
//  AlbumGroup.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "AlbumGroup.h"


@implementation AlbumGroup

@dynamic isExisted;
@dynamic persistentID;
@dynamic whetherToDisplay;
@dynamic whetherToScan;
@dynamic uniqueURLString;
@dynamic photoCount;
@dynamic photoes;

+ (NSString *)entityName
{
    return @"AlbumGroup";
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:moc];
}

@end
