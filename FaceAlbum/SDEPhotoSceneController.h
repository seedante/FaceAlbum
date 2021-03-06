//
//  SDEPhotoViewController.h
//  FaceAlbum
//
//  Created by seedante on 11/17/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPhotoSceneController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet UIView *warnningView;
@property (weak, nonatomic) IBOutlet UIView *accessErrorView;
@property (weak, nonatomic) IBOutlet UILabel *updateIndicator;

- (IBAction)changeShowStyle:(id)sender;

@end
