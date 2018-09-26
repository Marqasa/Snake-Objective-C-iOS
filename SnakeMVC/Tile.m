//
//  Tile.m
//  SnakeMVC
//
//  Created by Siesta on 01/06/2014.
//  Copyright (c) 2014 Siesta. All rights reserved.
//

#import "Tile.h"

@implementation Tile

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (self.isWall) {
		CGContextSetRGBFillColor(context, 0, 0, 0, 1);
		CGContextFillRect(context, self.bounds);
	} else if (self.isHead) {
		CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
		CGContextFillRect(context, self.bounds);
		UIBezierPath *head = [[UIBezierPath alloc] init];
		if (self.facing == 1) {
			[head moveToPoint:CGPointMake(0, self.bounds.size.height)];
			[head addLineToPoint:CGPointMake(0, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), 0)];
			[head addLineToPoint:CGPointMake(self.bounds.size.width, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
		} else if (self.facing == 2) {
			[head moveToPoint:CGPointMake(0, 0)];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), 0)];
			[head addLineToPoint:CGPointMake(self.bounds.size.width, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), self.bounds.size.height)];
			[head addLineToPoint:CGPointMake(0, self.bounds.size.height)];
		} else if (self.facing == 3) {
			[head moveToPoint:CGPointMake(self.bounds.size.width, 0)];
			[head addLineToPoint:CGPointMake(self.bounds.size.width, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), self.bounds.size.height)];
			[head addLineToPoint:CGPointMake(0, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake(0, 0)];
		} else if (self.facing == 4) {
			[head moveToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), self.bounds.size.height)];
			[head addLineToPoint:CGPointMake(0, (self.bounds.size.height / 2))];
			[head addLineToPoint:CGPointMake((self.bounds.size.width / 2), 0)];
			[head addLineToPoint:CGPointMake(self.bounds.size.width, 0)];
		}
		[head closePath];
		[head setLineWidth:1];
		[[UIColor redColor] setFill];
		[[UIColor purpleColor] setStroke];
		[head fill];
		[head stroke];
	} else if (self.isBody) {
		CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
		CGContextSetStrokeColorWithColor(context, [[UIColor purpleColor] CGColor]);
		CGContextFillRect(context, self.bounds);
		CGContextStrokeRect(context, self.bounds);
	} else if (self.isTail) {
		CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
		CGContextSetStrokeColorWithColor(context, [[UIColor purpleColor] CGColor]);
		CGContextFillRect(context, self.bounds);
		CGContextStrokeRect(context, self.bounds);
	} else if (self.isFruit) {
		CGContextSetRGBFillColor(context, 0.2, 0.8, 0.5, 1);
		CGContextFillRect(context, self.bounds);
	} else {
		CGContextSetRGBFillColor(context, 1, 1, 1, 1);
		CGContextFillRect(context, self.bounds);
	}
}

@end
