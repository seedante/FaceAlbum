//
//  SDEGalleryModel.h
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDEGalleryModel : NSObject

- (UICollectionViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
//- (NSUInteger)indexOfViewController:(UICollectionViewController *)viewController;

@end
