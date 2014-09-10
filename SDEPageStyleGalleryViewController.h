//
//  SDEPageStyleGalleryViewController.h
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPageStyleGalleryViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameTitle;
@property (weak, nonatomic) IBOutlet UILabel *infoTitle;
@property (weak, nonatomic) IBOutlet UITabBar *styleSwitch;
@property (weak, nonatomic) IBOutlet UICollectionView *galleryView;
- (IBAction)callActionCenter:(id)sender;

@end
