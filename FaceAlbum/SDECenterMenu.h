//
//  SphereMenu.h
//  SphereMenu
//
//  Created by Tu You on 14-8-24.
//  Copyright (c) 2014年 TU YOU. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SDECenterMenuDelegate <NSObject>

- (void)menuDidSelected:(int)index;

@end

@interface SDECenterMenu : UIView

@property (weak, nonatomic) id<SDECenterMenuDelegate> delegate;

- (instancetype)initWithStartPoint:(CGPoint)startPoint
                        startImage:(UIImage *)startImage
                     submenuImages:(NSArray *)images;

@end
