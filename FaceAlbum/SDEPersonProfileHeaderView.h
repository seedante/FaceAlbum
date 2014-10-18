//
//  SDEPersonProfileHeaderView.h
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDEMontageRoomViewController.h"

@interface SDEPersonProfileHeaderView : UICollectionReusableView

@property (nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic) IBOutlet UILabel *numberLabel;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (nonatomic, assign) int32_t personOrder;
@property (weak, nonatomic) SDEMontageRoomViewController *delegate;

- (IBAction)userEndInput:(id)sender;
- (IBAction)trainAvatorsInSection:(id)sender;

@end
