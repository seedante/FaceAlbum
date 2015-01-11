//
//  SDESpecialItemVC.h
//  FaceAlbum
//
//  Created by seedante on 11/17/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPhotoItemVC : UICollectionViewController

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
- (void)specifyStartIndexPath:(NSIndexPath *)indexPath;

@end
