//
//  SDViewController.h
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEScanRoomViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *assetCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *faceCollectionView;
@property (nonatomic) NSMutableArray *showAssets;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;

- (IBAction)scanPhotos:(id)sender;

@end
