//
//  SDEGalleryModel.m
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEGalleryModel.h"

@implementation SDEGalleryModel

- (UICollectionViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{
    UICollectionViewController *avatorViewController = [storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
    return avatorViewController;
}

@end
