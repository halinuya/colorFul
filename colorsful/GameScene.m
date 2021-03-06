//
//  GameScene.m
//  colorsful
//
//  Created by James wu on 15/5/11.
//  Copyright (c) 2015年 James wu. All rights reserved.
//

#import "GameScene.h"
@interface GameScene ()

@property (nonatomic) CGFloat SquareLength;
@property (nonatomic) CGPoint backgroundOrigin;

@property (nonatomic ,strong) NSMutableArray *colorFulSquares;
@property (nonatomic,strong) dispatch_queue_t dealQueue;
@end

@implementation GameScene
- (id)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if (self)
    {
        self.backgroundColor = [UIColor cyanColor];
        self.dealQueue = dispatch_queue_create("com.tallmantech.colorful", DISPATCH_QUEUE_SERIAL);
        self.colorFulSquares = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)didMoveToView:(SKView *)view {
    self.backgroundColor = [UIColor cyanColor];
    [self addBackground];
    [self addSquare];
}

#pragma mark - init and layout
- (void)addSquare
{
    // 1 设置彩色方砖的长度
    CGFloat colorSquareLength = _SquareLength - 8;
    
    int index = 5;
    SKSpriteNode *node;
    
    for ( int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            
            // 2 产生随机数对6求余， 结果会有0，1，2，3，4，5，保证有1/6的
            // 空闲，如果结果5，就不添加彩色方砖。
            index = arc4random()%6;
//            NSLog(@"%d",index);
            if (index == 5) {
                continue;
            }
            
            // 3 根据0到4的结果，初始化不同颜色彩色方砖。
            switch (index) {
                case 0:
                    node = [[SKSpriteNode alloc] initWithColor:[UIColor yellowColor] size:CGSizeMake(colorSquareLength, colorSquareLength)];
                    break;
                case 1:
                    node = [[SKSpriteNode alloc] initWithColor:[UIColor magentaColor] size:CGSizeMake(colorSquareLength, colorSquareLength)];
                    break;
                case 2:
                    node = [[SKSpriteNode alloc] initWithColor:[UIColor orangeColor] size:CGSizeMake(colorSquareLength, colorSquareLength)];
                    break;
                case 3:
                    node = [[SKSpriteNode alloc] initWithColor:[UIColor purpleColor] size:CGSizeMake(colorSquareLength, colorSquareLength)];
                    break;
                case 4:
                    node = [[SKSpriteNode alloc] initWithColor:[UIColor brownColor] size:CGSizeMake(colorSquareLength, colorSquareLength)];
                    break;
                default:
                    break;
            }
            
            // 4 指定节点的位置。
            CGFloat positionX = _backgroundOrigin.x + _SquareLength/2+ _SquareLength*j;
            CGFloat positionY = _backgroundOrigin.y + _SquareLength/2+ _SquareLength*i;
            node.position = CGPointMake(positionX, positionY);
            
            NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"colorSquare",@"nodeType",[NSValue valueWithCGPoint:CGPointMake(positionX, positionY)],@"position",[node color],@"color",@"YES",@"exsit",nil];
            //            NSLog(@"userData:%@",userData);
            node.userData = userData;
            
            // 5 设置节点的名字，并加入到scene场景。
            node.name = @"colorSquare";
            [self.colorFulSquares addObject:node];
            
            [self addChild:node];
        }
    }
}

-(void)addBackground
{
    // 1 获取当前Scene的款度和高度
    CGFloat width = self.size.width;
//    CGFloat height = self.size.height;
    
    // 2 因为需要8*8的方格背景，获取单个方格的宽度
    _SquareLength = width / 8;
    CGFloat SqureLength = _SquareLength;
    
    // 3 背景需要居中，因为坐标系原点在左下，所以高度设置在一半减去4个方格的长度
//    _backgroundOrigin = CGPointMake(0, height/2 - SqureLength*4);
    _backgroundOrigin = CGPointMake(0, SqureLength);
    // 4 挂载背景方格
    SKSpriteNode *node;
    for ( int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            
            // 4.1 初始化棋牌格的颜色和大小
            if ( (i%2 == 0 && j%2 == 0) || (i%2 == 1 && j%2 == 1)) {
                node = [[SKSpriteNode alloc] initWithColor:[UIColor lightGrayColor] size:CGSizeMake(SqureLength, SqureLength)];
            }
            else {
                node = [[SKSpriteNode alloc] initWithColor:[UIColor whiteColor] size:CGSizeMake(SqureLength, SqureLength)];
            }
            
            // 4.2 设置棋盘格的位置
            CGFloat positionX = _backgroundOrigin.x + SqureLength/2+ SqureLength*j;
            CGFloat positionY = _backgroundOrigin.y + SqureLength/2+ SqureLength*i;
            node.position = CGPointMake(positionX, positionY);
            
            NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"backSquare",@"nodeType",[NSValue valueWithCGPoint:CGPointMake(positionX, positionY)],@"position", nil];
//            NSLog(@"userData:%@",userData);
            node.userData = userData;
            
            node.name = @"backSquare";
            [self addChild:node];
        }
    }
}

#pragma mark - touch process
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    CGPoint nodePosition = [self nodePosition:location];
    SKNode *node = [self nodeAtPoint:nodePosition];
    
    if ([node.name isEqual:@"backSquare"])
    {
//        [self debugColorSquareInfo:node];
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.dealQueue, ^{
            [weakSelf dealWithBackNode:node];
            if (![self isExsitColorSquareToEliminate])
            {
                [self refreshGame];
                NSLog(@"refresh game");
            }
            
        });
    }
    else if ([node.name isEqual:@"colorSquare"])
    {

    }

}

- (void)dealWithBackNode:(SKNode *)node
{
    NSMutableArray *tempArray;
    tempArray = [self findFourDirectSquareOfSKNode:node];
    //    NSLog(@"colorNodes:%@",tempArray);
    
    NSMutableDictionary *resultDic = [self findSameSquareInArray:tempArray];
    //    NSLog(@"resultDic:%@", resultDic);
    
    [resultDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableArray *array = (NSMutableArray *)obj;
        if ([array count] > 1) {
            for (SKNode *node in array) {
                [node.userData setObject:@"NO" forKey:@"exsit"];
                SKAction *fadeOut = [SKAction fadeOutWithDuration:0.5];
                SKAction *removeAction = [SKAction removeFromParent];
                SKAction *all = [SKAction sequence:@[fadeOut, removeAction]];
                [node runAction:all];
            }
        }
    }];
    
}

- (void)refreshGame
{
    for ( SKNode *node in self.colorFulSquares)
    {
        [node removeFromParent];
    }
    
    [self.colorFulSquares removeAllObjects];
    
    [self addSquare];
}


- (BOOL)isExsitColorSquareToEliminate
{
    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            CGPoint p = CGPointMake(_backgroundOrigin.x + _SquareLength/2 + i*_SquareLength, _backgroundOrigin.y + _SquareLength/2 + j*_SquareLength);
            SKNode *node = [self nodeAtPoint:p];
            if ([node.name isEqual:@"backSquare"])
            {
                NSMutableArray *tempArray = [self findFourDirectSquareOfSKNode:node];
                NSMutableDictionary *resultDic;
                resultDic = [self findSameSquareInArray:tempArray];
                
                for (NSString *key in resultDic  )
                {
                    NSMutableArray *array = (NSMutableArray *)[resultDic objectForKey:key];
                    if ([array count] > 1)
                    {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (NSMutableDictionary *)findSameSquareInArray:(NSMutableArray *)tempArray
{
    //    NSLog(@"colorNodes:%@",tempArray);
    
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    for (SKNode *node in tempArray)
    {
        NSMutableArray *valueArray;
        UIColor *color = [node.userData objectForKey:@"color"];
        if (color == nil) {
            return nil;
        }
        
        if ([resultDic objectForKey:color] == nil)
        {
            valueArray = [[NSMutableArray alloc] init];
            
        }
        else
        {
            valueArray = (NSMutableArray *)[resultDic objectForKey:color];
        }
        
        [valueArray addObject:node];
        [resultDic setObject:valueArray forKey:color];
    }
    return resultDic;
}

- (NSMutableArray *)findFourDirectSquareOfSKNode:(SKNode *)node
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    NSValue *positionValue = (NSValue *)[node.userData objectForKey:@"position"];
    CGPoint position = [positionValue CGPointValue];
    
    CGFloat positionX = position.x;
    CGFloat positionY = position.y;
    
    CGFloat minX = _backgroundOrigin.x+_SquareLength/2;
    CGFloat minY = _backgroundOrigin.y+_SquareLength/2;
    
    CGFloat maxX = _backgroundOrigin.x+_SquareLength/2 + _SquareLength*7;
    CGFloat maxY = _backgroundOrigin.y+_SquareLength/2 + _SquareLength*7;
    
    // 1 left
    for (CGFloat x = positionX - _SquareLength; x >= minX; x=x-_SquareLength) {
        SKNode *node = [self nodeAtPoint:CGPointMake(x, positionY)];
        if ([self isExsitColorNode:node]) {
            [tempArray addObject:node];
            break;
        }
    }
    
    // 2 right
    for (CGFloat x = positionX + _SquareLength; x <= maxX; x=x+_SquareLength) {
        SKNode *node = [self nodeAtPoint:CGPointMake(x, positionY)];
        if ([self isExsitColorNode:node]) {
            [tempArray addObject:node];
            break;
        }
    }
    
    // 3 down
    for (CGFloat y = positionY - _SquareLength; y >= minY; y=y-_SquareLength) {
        SKNode *node = [self nodeAtPoint:CGPointMake(positionX , y)];
        if ([self isExsitColorNode:node]) {
            [tempArray addObject:node];
            break;
        }
    }
    
    // 4 up
    for (CGFloat y = positionY + _SquareLength; y <= maxY; y=y+_SquareLength) {
        SKNode *node = [self nodeAtPoint:CGPointMake(positionX , y)];
        if ([self isExsitColorNode:node]) {
            [tempArray addObject:node];
            break;
        }
    }
    return tempArray;
}

#pragma mark - time process
-(void)update:(CFTimeInterval)currentTime
{

}

#pragma mark - helper method
- (BOOL)isSameColorNode:(SKNode *)node WithNode:(SKNode *)OtherNode
{
    return [[node.userData objectForKey:@"color"] isEqual:[OtherNode.userData objectForKey:@"color"]];
}

- (BOOL)isExsitColorNode:(SKNode *)node
{
    if ([node.name isEqual:@"colorSquare"] && [[node.userData objectForKey:@"exsit"] isEqualToString:@"YES"]) {
        return YES;
    }
    return NO;
}

- (CGPoint)nodePosition:(CGPoint)location
{
    int countX = (location.x - _backgroundOrigin.x)/_SquareLength;
    int countY = (location.y - _backgroundOrigin.y)/_SquareLength;
    CGFloat x = _backgroundOrigin.x + countX*_SquareLength + _SquareLength/2;
    CGFloat y = _backgroundOrigin.y + countY*_SquareLength + _SquareLength/2;
    //    NSLog(@"[%f,%f,%f,%f,%d,%d]:%f",location.x,location.y,x,y,countX,countY,_SquareLength);
    return CGPointMake(x, y);
}


#pragma mark - debug
- (void)debugColorSquareInfo:(SKNode *)node
{
    if (node.userData != nil) {
        NSDictionary *infoDic = node.userData;
        NSLog(@"nodeType:%@",[infoDic objectForKey:@"nodeType"]);
        NSLog(@"position:%@",[infoDic objectForKey:@"position"]);
        NSLog(@"color:%@",[infoDic objectForKey:@"color"]);
    }
    
}

@end
