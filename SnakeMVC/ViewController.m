//
//  ViewController.m
//  SnakeMVC
//
//  Created by Siesta on 01/06/2014.
//  Copyright (c) 2014 Siesta. All rights reserved.
//

#import "ViewController.h"

#define BOARDSIZE	256
#define UP			1
#define RIGHT		2
#define DOWN		3
#define LEFT		4

@interface ViewController()

@property (nonatomic, strong) NSTimer *gameTimer;
@property (nonatomic) float tileSize, gameSpeed;
@property (nonatomic) NSUInteger headPos, tailPos, fruitPos, snakeLength, moves, newDirection, col, row, routeID;
@property (nonatomic, getter = isPaused) BOOL paused;
@property (nonatomic) BOOL aiMode, upSafe, rightSafe, downSafe, leftSafe, stuck;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.col = sqrt(BOARDSIZE);
	self.row = 1;
	self.tileSize = self.view.bounds.size.width / self.col;
	self.aiMode = YES;
	[self newGame];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Create a new game with a board the size of BOARDSIZE:
- (void)newGame {
	self.board = [[NSMutableArray alloc] initWithCapacity:BOARDSIZE];
	self.gameSpeed = 0.1;
	
	// Fill the board with tiles:
	for (int x = 0, i = 0; x < self.col; x++) {
		for (int y = 0; y < self.col; y++) {
			Tile *tile = [[Tile alloc] initWithFrame:CGRectMake(x * self.tileSize, y * self.tileSize, self.tileSize, self.tileSize)];
			tile.col = x;
			tile.row = y;
			
			// Set the tile type:
			if (x == 0 || x == (self.col - self.row) || y == 0 || y == (self.col - self.row)) {
				tile.wall = YES;
			}
			
			[self.board addObject:tile];
			[self.view addSubview:tile];
			tile.tileID = i;
			i++;
		}
	}
	
	// Add the snake:
	self.headPos = (self.col * 2) + (self.row * 1);
	self.tailPos = self.headPos - (self.col * 2);
	self.newDirection = RIGHT;
	[self.board[self.headPos] setHead:YES];
	[self.board[self.headPos] setFacing:self.newDirection];
	[self.board[self.headPos - self.col] setBody:YES];
	[self.board[self.headPos - self.col] setFacing:self.newDirection];
	[self.board[self.tailPos] setTail:YES];
	[self.board[self.tailPos] setFacing:self.newDirection];
	self.snakeLength = 3;
	
	// Add a fruit:
	[self newFruit];
	
	// Start the game:
	self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:self.gameSpeed target:self selector:@selector(gameLoop:) userInfo:nil repeats:YES];
	[self gameLoop:self.gameTimer];
}

// Move tile with direction:
- (void)moveTile:(int)tile withDirection:(int)direction {
	
	BOOL hasMoved = NO;
	
	// Head:
	if ([self.board[tile] isHead] && ![self.board[tile] isTail] && !hasMoved) {
		
		// Make a note of current direction before setting new direction:
		int oldDirection = [self.board[tile] facing];
		[self.board[tile] setFacing:direction];
		
		// Update head position based on direction:
		switch (direction) {
			case UP:
				self.headPos = tile - self.row;
				break;
			case RIGHT:
				self.headPos = tile + self.col;
                break;
            case DOWN:
				self.headPos = tile + self.row;
				break;
            case LEFT:
				self.headPos = tile - self.col;
				break;
		}
		[self.board[self.headPos] setHead:YES];
		self.moves++;
		
		// Check for game over:
		if ([self.board[self.headPos] isBody] || [self.board[self.headPos] isWall]) {
			[self gameOver];
			goto end;
		}
		
		[self.board[self.headPos] setFacing:direction];
		[self.board[self.headPos] setNeedsDisplay];
		[self.board[tile] setHead:NO];
		
		// Move next tile:
		switch (oldDirection) {
			case UP:
				[self moveTile:(tile + self.row) withDirection:UP];
				break;
			case RIGHT:
				[self moveTile:(tile - self.col) withDirection:RIGHT];
				break;
			case DOWN:
				[self moveTile:(tile - self.row) withDirection:DOWN];
				break;
			case LEFT:
				[self moveTile:(tile + self.col) withDirection:LEFT];
				break;
		}
		
		// Mark tile as moved to avoid moving it twice:
	end:
		hasMoved = YES;
	}
	
	// Body:
	if ([self.board[tile] isBody] && !hasMoved) {
		
		int oldDirection = [self.board[tile] facing];
		[self.board[tile] setFacing:direction];
		
		int bodyPos = 0;
		switch (direction) {
			case UP:
				bodyPos = tile - self.row;
				break;
			case RIGHT:
				bodyPos = tile + self.col;
				break;
			case DOWN:
				bodyPos = tile + self.row;
				break;
			case LEFT:
				bodyPos = tile - self.col;
				break;
		}
		[self.board[bodyPos] setBody:YES];
		[self.board[bodyPos] setFacing:direction];
		[self.board[bodyPos] setNeedsDisplay];
		[self.board[tile] setBody:NO];
		
		switch (oldDirection) {
			case UP:
				[self moveTile:(tile + self.row) withDirection:UP];
				break;
			case RIGHT:
				[self moveTile:(tile - self.col) withDirection:RIGHT];
				break;
			case DOWN:
				[self moveTile:(tile - self.row) withDirection:DOWN];
				break;
			case LEFT:
				[self moveTile:(tile + self.col) withDirection:LEFT];
				break;
		}
		
		hasMoved = YES;
	}
	
	// Tail:
	if ([self.board[tile] isTail] && !hasMoved) {
		
		// If the snake eats a piece of fruit:
		if ([self.board[self.headPos] isFruit]) {
			
			[self.board[tile] setFacing:direction];
			
			// Add a new body tile and update snake length:
			int bodyPos = 0;
			switch (direction) {
				case UP:
					bodyPos = tile - self.row;
					break;
				case RIGHT:
					bodyPos = tile + self.col;
					break;
				case DOWN:
					bodyPos = tile + self.row;
					break;
				case LEFT:
					bodyPos = tile - self.col;
					break;
			}
			[self.board[bodyPos] setBody:YES];
			[self.board[bodyPos] setFacing:direction];
			[self.board[bodyPos] setNeedsDisplay];
			self.snakeLength++;
			[self newFruit];
			
		} else {
			// Update tail position:
			switch (direction) {
				case UP:
					self.tailPos = tile - self.row;
					break;
				case RIGHT:
					self.tailPos = tile + self.col;
					break;
				case DOWN:
					self.tailPos = tile + self.row;
					break;
				case LEFT:
					self.tailPos = tile - self.col;
					break;
			}
			[self.board[self.tailPos] setTail:YES];
			[self.board[self.tailPos] setNeedsDisplay];
			[self.board[tile] setTail:NO];
			[self.board[tile] setNeedsDisplay];
			
			// Only clear direction if the head is not directly behind the tail:
			if (![self.board[tile] isHead]) {
				[self.board[tile] setFacing:0];
			}
		}
	}
}

// Add a new fruit to the board:
- (void)newFruit {
	[self.board[self.headPos] setFruit:NO];
	self.routeID = [self.board[self.headPos] tileID];
	//self.gameScore += 5;
	//self.gameSpeed *= 0.995;
	//self.snakeHue = self.fruitHue;
	
	// Only add a new fruit if there is still space on the board:
	if (self.snakeLength < (BOARDSIZE - ((self.col * 4) - 4))) {
		BOOL isSet = NO;
		while (!isSet) {
			int i = arc4random() % BOARDSIZE;
			// Only add a fruit if the tile is free:
			if (![self.board[i] isWall] && ![self.board[i] isHead] && ![self.board[i] isBody] && ![self.board[i] isTail]) {
				[self.board[i] setFruit:YES];
				[self.board[i] setNeedsDisplay];
				self.fruitPos = i;
				isSet = YES;
			}
		}
		self.moves = 0;
		//self.fruitHue = ((arc4random() % 20) * 0.05);
	} else {
		//[self victory];
	}
	//[self.gameSpeed invalidate];
	//self.gameSpeed = [NSTimer scheduledTimerWithTimeInterval:self.gameSpeed target:self selector:@selector(gameLoop:) userInfo:nil repeats:YES];
}

// The game loop:
- (void)gameLoop:(NSTimer *)timer {
	[self moveTile:self.headPos withDirection:self.newDirection];
	
	// If in AI mode:
	if (self.aiMode) {
		[self fruitAI];
		[self collisionAI];
	}
}

// A snake gotta eat!
- (void)fruitAI {
	
	// Directly down:
	if ([self.board[self.fruitPos] row] > [self.board[self.headPos] row] && [self.board[self.fruitPos] col] == [self.board[self.headPos] col]) {
		
		// If not currently going up, go down:
		if ([self.board[self.headPos] facing] != UP) {
			self.newDirection = DOWN;
		} else {
			
			// Go either left or right:
			if (arc4random() % 2 && ![self.board[self.headPos + self.col] isWall]) {
				self.newDirection = RIGHT;
			} else {
				self.newDirection = LEFT;
			}
		}
	}
	
	// Down right:
	if ([self.board[self.fruitPos] row] > [self.board[self.headPos] row] && [self.board[self.fruitPos] col] > [self.board[self.headPos] col]) {
		
		// Only change course if not already going down or right:
		if ([self.board[self.headPos] facing] != DOWN && [self.board[self.headPos] facing] != RIGHT) {
			
			// Go either down or right:
			if ([self.board[self.headPos] facing] == LEFT && ![self.board[self.headPos + self.row] isWall]) {
				self.newDirection = DOWN;
			} else {
				self.newDirection = RIGHT;
			}
		}
	}
	
	// Directly right:
	if ([self.board[self.fruitPos] row] == [self.board[self.headPos] row] && [self.board[self.fruitPos] col] > [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != LEFT) {
			self.newDirection = RIGHT;
		} else {
			if (arc4random() % 2 && ![self.board[self.headPos + self.row] isWall]) {
				self.newDirection = DOWN;
			} else {
				self.newDirection = UP;
			}
		}
	}
	
	// Up right:
	if ([self.board[self.fruitPos] row] < [self.board[self.headPos] row] && [self.board[self.fruitPos] col] > [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != RIGHT && [self.board[self.headPos] facing] != UP) {
            if ([self.board[self.headPos] facing] == DOWN && ![self.board[self.headPos + self.col] isWall]) {
				self.newDirection = RIGHT;
			} else {
				self.newDirection = UP;
			}
		}
	}
	
	// Directyly up:
	if ([self.board[self.fruitPos] row] < [self.board[self.headPos] row] && [self.board[self.fruitPos] col] == [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != DOWN) {
			self.newDirection = UP;
		} else {
			if (arc4random() % 2 && ![self.board[self.headPos + self.col] isWall]) {
				self.newDirection = RIGHT;
			} else {
				self.newDirection = LEFT;
			}
		}
	}
	
	// Up left:
	if ([self.board[self.fruitPos] row] < [self.board[self.headPos] row] && [self.board[self.fruitPos] col] < [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != UP && [self.board[self.headPos] facing] != LEFT) {
			if ([self.board[self.headPos] facing] == RIGHT && ![self.board[self.headPos - self.row] isWall]) {
				self.newDirection = UP;
			} else {
				self.newDirection = LEFT;
			}
		}
	}
	
	// Directly left:
	if ([self.board[self.fruitPos] row] == [self.board[self.headPos] row] && [self.board[self.fruitPos] col] < [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != RIGHT) {
			self.newDirection = LEFT;
		} else {
			if (arc4random() % 2 && ![self.board[self.headPos + self.row] isWall]) {
				self.newDirection = DOWN;
			} else {
				self.newDirection = UP;
			}
		}
	}
	
	// Down left:
	if ([self.board[self.fruitPos] row] > [self.board[self.headPos] row] && [self.board[self.fruitPos] col] < [self.board[self.headPos] col]) {
		if ([self.board[self.headPos] facing] != LEFT && [self.board[self.headPos] facing] != DOWN) {
			if ([self.board[self.headPos] facing] == RIGHT) {
				self.newDirection = DOWN;
			} else {
				self.newDirection = LEFT;
			}
		}
	}
}

- (void)collisionAI {
	[self resetChecks];
	[self checkUp:(self.headPos - self.row)];
	[self checkRight:(self.headPos + self.col)];
	[self checkDown:(self.headPos + self.row)];
	[self checkLeft:(self.headPos - self.col)];
	
start:
	switch (self.newDirection) {
		case UP:
			if (!self.upSafe) {
				self.newDirection = RIGHT;
				goto start;
			}
			break;
		case RIGHT:
			if (!self.rightSafe) {
				self.newDirection = DOWN;
				goto start;
			}
			break;
		case DOWN:
			if (!self.downSafe) {
				self.newDirection = LEFT;
				goto start;
			}
			break;
		case LEFT:
			if (!self.leftSafe) {
				self.newDirection = UP;
				goto start;
			}
			break;
	}
	
	//[self checkStuck];
	[self checkStuck2];
}

- (void)resetChecks {
	for (Tile *tile in self.board) {
		tile.upChecked = NO;
		tile.rightChecked = NO;
		tile.downChecked = NO;
		tile.leftChecked = NO;
	}
    self.upSafe = self.rightSafe = self.downSafe = self.leftSafe = NO;
}

- (BOOL)checkUp:(int)tile {
	
	// If this tile is a wall/body, is already checked or we already know up is safe, return no:
	if ([self.board[tile] isWall] || [self.board[tile] isBody] || [self.board[tile] upChecked] || self.upSafe) {
		return NO;
	}
	
	// If this tile is the tail, stop the search:
	if ([self.board[tile] isTail]) {
		self.upSafe = YES;
		return NO;
	}
	
	// Check the next tile to be the tail:
	if (![self.board[tile] isFruit]) {
		switch ([self.board[self.tailPos] facing]) {
			case 1:
				if (tile + self.row == self.tailPos - self.row || tile + self.col == self.tailPos - self.row || tile - self.col == self.tailPos - self.row) {
					self.upSafe = YES;
					return NO;
				}
				break;
			case 2:
				if (tile + self.row == self.tailPos + self.col || tile - self.row == self.tailPos + self.col || tile - self.col == self.tailPos + self.col) {
					self.upSafe = YES;
					return NO;
				}
				break;
			case 3:
				if (tile - self.col == self.tailPos + self.row || tile - self.row == self.tailPos + self.row || tile + self.col == self.tailPos + self.row) {
					self.upSafe = YES;
					return NO;
				}
				break;
			case 4:
				if (tile + self.col == self.tailPos - self.col || tile - self.row == self.tailPos - self.col || tile + self.row == self.tailPos - self.col) {
					self.upSafe = YES;
					return NO;
				}
				break;
		}
	}
	
	// Mark this tile as checked:
	[self.board[tile] setUpChecked:YES];
	
	// If the tile above is clear:
	if (![self.board[tile - self.row] isHead] && ![self.board[tile - self.row] isBody] && ![self.board[tile - self.row] isTail] && ![self.board[tile - self.row] isWall]) {
		
		// Check that tile:
		if ([self checkUp:(tile - self.row)] == YES) {
			return YES;
		}

	} else if ([self.board[tile - self.row] isTail]) {
		// We found the tail so we can stop searching:
		self.upSafe = YES;
		return NO;
	}
	
	// If the tile to the right is clear:
	if (![self.board[tile + self.col] isHead] && ![self.board[tile + self.col] isBody] && ![self.board[tile + self.col] isTail] && ![self.board[tile + self.col] isWall]) {
		
		// Check that tile:
		if ([self checkUp:(tile + self.col)] == YES) {
			return YES;
		}
		
	} else if ([self.board[tile + self.col] isTail]) {
		// We found the tail:
		self.upSafe = YES;
		return NO;
	}
	
	// If the tile below is clear:
	if (![self.board[tile + self.row] isHead] && ![self.board[tile + self.row] isBody] && ![self.board[tile + self.row] isTail] && ![self.board[tile + self.row] isWall]) {
		
		// Check that tile:
		if ([self checkUp:(tile + self.row)] == YES) {
			return YES;
		}
		
	} else if ([self.board[tile + self.row] isTail]) {
		// We found the tail:
		self.upSafe = YES;
		return NO;
	}
	
	// If the tile to the left is clear:
	if (![self.board[tile - self.col] isHead] && ![self.board[tile - self.col] isBody] && ![self.board[tile - self.col] isTail] && ![self.board[tile - self.col] isWall]) {
		
		// Check that tile:
		if ([self checkUp:(tile - self.col)] == YES) {
			return YES;
		}
		
	} else if ([self.board[tile - self.col] isTail]) {
		// We found the tail:
		self.upSafe = YES;
		return NO;
	}
	
	// This direction is not safe:
	return NO;
}

- (BOOL)checkRight:(int)tile {
	
	if ([self.board[tile] isWall] || [self.board[tile] isBody] || [self.board[tile] rightChecked] || self.rightSafe) {
		return NO;
	}
	
	if ([self.board[tile] isTail]) {
		self.rightSafe = YES;
		return NO;
	}
	
	if (![self.board[tile] isFruit]) {
		switch ([self.board[self.tailPos] facing]) {
			case 1:
				if (tile + self.row == self.tailPos - self.row || tile + self.col == self.tailPos - self.row || tile - self.col == self.tailPos - self.row) {
					self.rightSafe = YES;
					return NO;
				}
				break;
			case 2:
				if (tile + self.row == self.tailPos + self.col || tile - self.row == self.tailPos + self.col || tile - self.col == self.tailPos + self.col) {
					self.rightSafe = YES;
					return NO;
				}
				break;
			case 3:
				if (tile - self.col == self.tailPos + self.row || tile - self.row == self.tailPos + self.row || tile + self.col == self.tailPos + self.row) {
					self.rightSafe = YES;
					return NO;
				}
				break;
			case 4:
				if (tile + self.col == self.tailPos - self.col || tile - self.row == self.tailPos - self.col || tile + self.row == self.tailPos - self.col) {
					self.rightSafe = YES;
					return NO;
				}
				break;
		}
	}
	
	[self.board[tile] setRightChecked:YES];
	
	// Up:
	if (![self.board[tile - self.row] isHead] && ![self.board[tile - self.row] isBody] && ![self.board[tile - self.row] isTail] && ![self.board[tile - self.row] isWall]) {
		if ([self checkRight:(tile - self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.row] isTail]) {
		self.rightSafe = YES;
		return NO;
	}
	
	// Right:
	if (![self.board[tile + self.col] isHead] && ![self.board[tile + self.col] isBody] && ![self.board[tile + self.col] isTail] && ![self.board[tile + self.col] isWall]) {
		if ([self checkRight:(tile + self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.col] isTail]) {
		self.rightSafe = YES;
		return NO;
	}
	
	// Down:
	if (![self.board[tile + self.row] isHead] && ![self.board[tile + self.row] isBody] && ![self.board[tile + self.row] isTail] && ![self.board[tile + self.row] isWall]) {
		if ([self checkRight:(tile + self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.row] isTail]) {
		self.rightSafe = YES;
		return NO;
	}
	
	// Left:
	if (![self.board[tile - self.col] isHead] && ![self.board[tile - self.col] isBody] && ![self.board[tile - self.col] isTail] && ![self.board[tile - self.col] isWall]) {
		if ([self checkRight:(tile - self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.col] isTail]) {
		self.rightSafe = YES;
		return NO;
	}
	
	return NO;
}

- (BOOL)checkDown:(int)tile {
	
	if ([self.board[tile] isWall] || [self.board[tile] isBody] || [self.board[tile] downChecked] || self.downSafe) {
		return NO;
	}
	
	if ([self.board[tile] isTail]) {
		self.downSafe = YES;
		return NO;
	}
	
	if (![self.board[tile] isFruit]) {
		switch ([self.board[self.tailPos] facing]) {
			case 1:
				if (tile + self.row == self.tailPos - self.row || tile + self.col == self.tailPos - self.row || tile - self.col == self.tailPos - self.row) {
					self.downSafe = YES;
					return NO;
				}
				break;
			case 2:
				if (tile + self.row == self.tailPos + self.col || tile - self.row == self.tailPos + self.col || tile - self.col == self.tailPos + self.col) {
					self.downSafe = YES;
					return NO;
				}
				break;
			case 3:
				if (tile - self.col == self.tailPos + self.row || tile - self.row == self.tailPos + self.row || tile + self.col == self.tailPos + self.row) {
					self.downSafe = YES;
					return NO;
				}
				break;
			case 4:
				if (tile + self.col == self.tailPos - self.col || tile - self.row == self.tailPos - self.col || tile + self.row == self.tailPos - self.col) {
					self.downSafe = YES;
					return NO;
				}
				break;
		}
	}
	
	[self.board[tile] setDownChecked:YES];
	
	// Up:
	if (![self.board[tile - self.row] isHead] && ![self.board[tile - self.row] isBody] && ![self.board[tile - self.row] isTail] && ![self.board[tile - self.row] isWall]) {
		if ([self checkDown:(tile - self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.row] isTail]) {
		self.downSafe = YES;
		return NO;
	}
	
	// Right:
	if (![self.board[tile + self.col] isHead] && ![self.board[tile + self.col] isBody] && ![self.board[tile + self.col] isTail] && ![self.board[tile + self.col] isWall]) {
		if ([self checkDown:(tile + self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.col] isTail]) {
		self.downSafe = YES;
		return NO;
	}
	
	// Down:
	if (![self.board[tile + self.row] isHead] && ![self.board[tile + self.row] isBody] && ![self.board[tile + self.row] isTail] && ![self.board[tile + self.row] isWall]) {
		if ([self checkDown:(tile + self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.row] isTail]) {
		self.downSafe = YES;
		return NO;
	}
	
	// Left:
	if (![self.board[tile - self.col] isHead] && ![self.board[tile - self.col] isBody] && ![self.board[tile - self.col] isTail] && ![self.board[tile - self.col] isWall]) {
		if ([self checkDown:(tile - self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.col] isTail]) {
		self.downSafe = YES;
		return NO;
	}
	
	return NO;
}

- (BOOL)checkLeft:(int)tile {
	
	if ([self.board[tile] isWall] || [self.board[tile] isBody] || [self.board[tile] leftChecked] || self.leftSafe) {
		return NO;
	}
	
	if ([self.board[tile] isTail]) {
		self.leftSafe = YES;
		return NO;
	}
	
	if (![self.board[tile] isFruit]) {
		switch ([self.board[self.tailPos] facing]) {
			case 1:
				if (tile + self.row == self.tailPos - self.row || tile + self.col == self.tailPos - self.row || tile - self.col == self.tailPos - self.row) {
					self.leftSafe = YES;
					return NO;
				}
				break;
			case 2:
				if (tile + self.row == self.tailPos + self.col || tile - self.row == self.tailPos + self.col || tile - self.col == self.tailPos + self.col) {
					self.leftSafe = YES;
					return NO;
				}
				break;
			case 3:
				if (tile - self.col == self.tailPos + self.row || tile - self.row == self.tailPos + self.row || tile + self.col == self.tailPos + self.row) {
					self.leftSafe = YES;
					return NO;
				}
				break;
			case 4:
				if (tile + self.col == self.tailPos - self.col || tile - self.row == self.tailPos - self.col || tile + self.row == self.tailPos - self.col) {
					self.leftSafe = YES;
					return NO;
				}
				break;
		}
	}
	
	[self.board[tile] setLeftChecked:YES];
	
	// Up:
	if (![self.board[tile - self.row] isHead] && ![self.board[tile - self.row] isBody] && ![self.board[tile - self.row] isTail] && ![self.board[tile - self.row] isWall]) {
		if ([self checkLeft:(tile - self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.row] isTail]) {
		self.leftSafe = YES;
		return NO;
	}
	
	// Right:
	if (![self.board[tile + self.col] isHead] && ![self.board[tile + self.col] isBody] && ![self.board[tile + self.col] isTail] && ![self.board[tile + self.col] isWall]) {
		if ([self checkLeft:(tile + self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.col] isTail]) {
		self.leftSafe = YES;
		return NO;
	}
	
	// Down:
	if (![self.board[tile + self.row] isHead] && ![self.board[tile + self.row] isBody] && ![self.board[tile + self.row] isTail] && ![self.board[tile + self.row] isWall]) {
		if ([self checkLeft:(tile + self.row)] == YES) {
			return YES;
		}
	} else if ([self.board[tile + self.row] isTail]) {
		self.leftSafe = YES;
		return NO;
	}
	
	// Left:
	if (![self.board[tile - self.col] isHead] && ![self.board[tile - self.col] isBody] && ![self.board[tile - self.col] isTail] && ![self.board[tile - self.col] isWall]) {
		if ([self checkLeft:(tile - self.col)] == YES) {
			return YES;
		}
	} else if ([self.board[tile - self.col] isTail]) {
		self.leftSafe = YES;
		return NO;
	}
	
	return NO;
}

- (void)checkStuck {
	if (self.snakeLength > (BOARDSIZE * 0.5) && self.moves > self.snakeLength * 2) {
		int decision = arc4random() % 3;
		switch (self.newDirection) {
			case UP:
				switch (decision) {
					case 0:
						break;
					case 1:
						if (self.rightSafe) {
							self.newDirection = RIGHT;
						}
						break;
					case 2:
						if (self.leftSafe) {
							self.newDirection = LEFT;
						}
						break;
				}
				break;
			case RIGHT:
				switch (decision) {
					case 0:
						break;
					case 1:
						if (self.upSafe) {
							self.newDirection = UP;
						}
						break;
					case 2:
						if (self.downSafe) {
							self.newDirection = DOWN;
						}
						break;
				}
				break;
			case DOWN:
				switch (decision) {
					case 0:
						break;
					case 1:
						if (self.rightSafe) {
							self.newDirection = RIGHT;
						}
						break;
					case 2:
						if (self.leftSafe) {
							self.newDirection = LEFT;
						}
						break;
				}
				break;
			case LEFT:
				switch (decision) {
					case 0:
						break;
					case 1:
						if (self.upSafe) {
							self.newDirection = UP;
						}
						break;
					case 2:
						if (self.downSafe) {
							self.newDirection = DOWN;
						}
						break;
				}
				break;
		}
	}
}

- (void)checkStuck2 {
	if (self.moves >= self.snakeLength && self.routeID == [self.board[self.headPos] tileID]) {
		// route has been tried
		if (false) {
		}
	}
	// Need a way to determine if a route has been tried and try a new route accordingly. Reset everytime a fruit is eaten.
}

- (void)gameOver {
	[self.gameTimer invalidate];
}

@end
