//
//  SDEFaceRoomViewController.h
//  FaceAlbum
//
//  Created by seedante on 11/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDEPopupPanel.h"

@interface SDEFaceRoomViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameTitle;
@property (weak, nonatomic) IBOutlet UILabel *infoTitle;
@property (weak, nonatomic) IBOutlet UITabBar *librarySwitch;
@property (weak, nonatomic) IBOutlet UICollectionView *galleryView;
@property (weak, nonatomic) IBOutlet UIButton *actionCenterButton;
@property (weak, nonatomic) IBOutlet UIButton *MontageRoomButton;
@property (weak, nonatomic) IBOutlet UIButton *scanRoomButton;
@property (weak, nonatomic) IBOutlet SDEPopupPanel *buttonPanel;

@end
