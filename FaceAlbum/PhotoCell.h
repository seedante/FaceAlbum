//
//  PhotoCell.h
//  LayoutSample
//
//  Created by seedante on 14-8-1.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoCell : UICollectionViewCell

@property (nonatomic) ALAsset *asset;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@end
