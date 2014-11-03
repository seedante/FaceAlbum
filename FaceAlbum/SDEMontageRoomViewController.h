//
//  SDMontageRoomViewController.h
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDEReorderableCollectionViewFlowLayout.h"
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDEMontageRoomViewController : UICollectionViewController<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITextFieldDelegate>


- (void)trainModelAtSection:(NSInteger)section;

@end
