//
//  Person.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "Person.h"
#import "Face.h"


@implementation Person

@dynamic avatorImage;
@dynamic portraitFileString;
@dynamic faceCount;
@dynamic name;
@dynamic personID;
@dynamic order;
@dynamic photoCount;
@dynamic whetherToDisplay;
@dynamic ownedFaces;


+(NSString *)entityName
{
    return @"Person";
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:moc];
}

@end
