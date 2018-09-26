//
//  Tile.h
//  SnakeMVC
//
//  Created by Siesta on 01/06/2014.
//  Copyright (c) 2014 Siesta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Tile : UIView

@property (nonatomic, getter = isWall) BOOL wall;
@property (nonatomic, getter = isHead) BOOL head;
@property (nonatomic, getter = isBody) BOOL body;
@property (nonatomic, getter = isTail) BOOL tail;
@property (nonatomic, getter = isFruit) BOOL fruit;
@property (nonatomic) NSUInteger facing, col, row, tileID;
@property (nonatomic) BOOL upChecked, rightChecked, downChecked, leftChecked;

@end
