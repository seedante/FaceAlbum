//
//  FaceppInfo.m
//  ImageCapture
//
//  Created by youmu on 12-11-27.
//  Copyright (c) 2012年 Megvii. All rights reserved.
//

#import "FaceppInfo.h"
#import "FaceppClient.h"

@implementation FaceppInfo

-(FaceppResult*) getApp {
    return [FaceppClient requestWithFunction:@"info/get_app" params:nil];
}

-(FaceppResult*) getFaceWithFaceId:(NSString*)faceId {
    return [FaceppClient requestWithFunction:@"info/get_face" params:[NSArray arrayWithObjects:@"face_id", faceId, nil]];
}

-(FaceppResult*) getGroupList {
    return [FaceppClient requestWithFunction:@"info/get_group_list" params:nil];
}

-(FaceppResult*) getImageWithImgId:(NSString*)imageId {
    return [FaceppClient requestWithFunction:@"info/get_image" params:[NSArray arrayWithObjects:@"img_id", imageId, nil]];
}

-(FaceppResult*) getPersonList {
    return [FaceppClient requestWithFunction:@"info/get_person_list" params:nil];
}

-(FaceppResult*) getFacesetList {
    return [FaceppClient requestWithFunction:@"info/get_faceset_list" params:nil];
}

-(FaceppResult*) getQuota {
    return [FaceppClient requestWithFunction:@"info/get_quota" params:nil];
}

-(FaceppResult*) getSessionWithSessionId:(NSString*)sessionId {
    return [FaceppClient requestWithFunction:@"info/get_session" params:[NSArray arrayWithObjects:@"session_id", sessionId, nil]];
}

@end
