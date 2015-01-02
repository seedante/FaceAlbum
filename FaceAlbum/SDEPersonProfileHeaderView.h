//
//  SDEPersonProfileHeaderView.h
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "SDEMontageRoomViewController.h"

@protocol  SDEUICollectionSupplementaryViewDelegate <NSObject>
@property (nonatomic, assign) BOOL isChoosingAvator;
@property (nonatomic, assign) NSInteger editedSection;

@end

@interface SDEPersonProfileHeaderView : UICollectionReusableView

@property (nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatorImageView;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (nonatomic, assign) NSInteger section;
@property (weak, nonatomic) id<SDEUICollectionSupplementaryViewDelegate> delegate;
@property (nonatomic, copy) NSString *assetURLString;
@property (nonatomic) NSValue *portraitAreaRectValue;
@property (nonatomic, copy) NSString *storePath;

- (IBAction)userEndInput:(id)sender;
- (IBAction)performChooseAction:(id)sender;
@end
