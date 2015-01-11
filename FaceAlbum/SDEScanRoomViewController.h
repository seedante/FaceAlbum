//
//  SDViewController.h
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEScanRoomViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *assetCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *faceCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;

- (IBAction)scanPhotos:(id)sender;

@end
