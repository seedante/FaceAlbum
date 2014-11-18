//
//  SDEPageStyleGalleryViewController.h
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDEPopupPanel.h"
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDEPageStyleGalleryViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UITabBarDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameTitle;
@property (weak, nonatomic) IBOutlet UILabel *infoTitle;
@property (weak, nonatomic) IBOutlet UITabBar *styleSwitch;
@property (weak, nonatomic) IBOutlet UICollectionView *galleryView;
@property (weak, nonatomic) IBOutlet SDEPopupPanel *buttonPanel;
@property (weak, nonatomic) IBOutlet UIButton *scanRoomButton;
@property (weak, nonatomic) IBOutlet UIButton *MontageRoomButton;
@property (weak, nonatomic) IBOutlet UIButton *actionCenterButton;


- (IBAction)scanPhotoLibrary:(id)sender;
- (IBAction)editAlbum:(id)sender;
- (IBAction)popMenu:(id)sender;
@end
