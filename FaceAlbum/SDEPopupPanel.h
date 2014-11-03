//
//  SDEPopupPanel.h
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDEPopupPanel : UIView

@property (nonatomic, assign) CGRect popupRect;
@property (nonatomic, assign) CGRect hideRect;
@property (nonatomic, assign) CGFloat panelHeight;
@property (nonatomic) BOOL isPopup;

- (void)popup;
- (void)hide;

@end
