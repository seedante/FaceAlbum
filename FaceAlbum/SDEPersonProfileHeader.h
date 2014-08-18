//
//  SDEPersonProfileHeader.h
//  FaceAlbum
//
//  Created by seedante on 14-8-15.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPersonProfileHeader : UICollectionReusableView


@property (nonatomic) IBOutlet UIImageView *personAvatorView;
- (IBAction)selectAllFaces:(id)sender;
- (void)setAvator:(UIImage *)image;
@end
