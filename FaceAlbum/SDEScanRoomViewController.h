//
//  SDViewController.h
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDEScanRoomViewController : UIViewController<UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *assetCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *faceCollectionView;
@property (nonatomic) NSMutableArray *showAssets;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIView *requestPhotoAuthorizationView;

- (IBAction)scanPhotos:(id)sender;

@end
