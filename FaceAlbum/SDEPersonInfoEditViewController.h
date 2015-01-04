//
//  SDEPersonInfoEditViewController.h
//  FaceAlbum
//
//  Created by seedante on 1/4/15.
//  Copyright (c) 2015 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPersonInfoEditViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *candidateAvatorCollectionView;
@property (nonatomic, assign) NSInteger secction;

- (IBAction)saveAllModify:(id)sender;
- (IBAction)cancelAllModify:(id)sender;
@end
