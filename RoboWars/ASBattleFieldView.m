//
//  ASBattleFieldView.m
//  RoboWars
//
//  Created by Oleksii Skutarenko on 13.10.13.
//  Copyright (c) 2013 Alex Skutarenko. All rights reserved.
//

#import "ASBattleFieldView.h"
#import "AKUtils.h"

@interface ASBattleFieldView ()

@property (assign, nonatomic) CGRect fieldRect;
@property (assign, nonatomic) CGFloat cellSize;

@end

@implementation ASBattleFieldView

- (void) reloadData {
    [self setNeedsDisplay];
}

- (void) animateShotTo:(CGPoint) coordinate fromRect:(CGRect) rect {

    // коорд робота в fieldRect
    CGRect robotRect = [self rectFromRelativeRect:rect];
    // коорд ShotTo в fieldRect
    CGRect shotRect = [self rectFromRelativeRect:CGRectMake(coordinate.x, coordinate.y, 1, 1)];
    
    // выстрел идет с середины робота
    CGPoint start = CGPointMake(CGRectGetMidX(robotRect), CGRectGetMidY(robotRect));
    // заканчивается выстрел в середине ShotTo
    CGPoint end = CGPointMake(CGRectGetMidX(shotRect), CGRectGetMidY(shotRect));
    
    // вью - пуля
    UIView* bullet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    bullet.backgroundColor = [UIColor redColor];
    bullet.center = start;
    [self addSubview:bullet];
    
    // по теореме пифагора а2 + в2 = с2
    CGFloat distance = sqrt( (end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y) );
    CGFloat distanceHypot = hypotf(start.x - end.x, start.y - end.y); // distance через гипотенузу
    
    CGFloat speed = 2000;
    
    [UIView animateWithDuration:distance / speed
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         // перемещаем пулю
                         bullet.center = end;
                     }
                     completion:^(BOOL finished) {
                         [bullet removeFromSuperview];
                         // обновим чтобы видеть изменения 
                         [self reloadData];
                     }];
        
}


#pragma mark - Helpers

- (CGRect) rectFromRelativeRect:(CGRect) relative {
    // отсчитаем координаты робота в системе View frame из системы 11 на 11 клеток
    CGRect rect = CGRectMake(CGRectGetMinX(self.fieldRect) + self.cellSize * CGRectGetMinX(relative),
                             CGRectGetMinY(self.fieldRect) + self.cellSize * CGRectGetMinY(relative),
                             self.cellSize * CGRectGetWidth(relative),
                             self.cellSize * CGRectGetHeight(relative));
    
    
    return rect;
}


#pragma mark - View Rendering

- (void)drawRect:(CGRect)rect
{
    if (!self.dataSource) {
        return;
    }
    
    // получаем размер поля 11
    CGSize fieldSize = [self.dataSource sizeForBattleField:self];
    
    if (fieldSize.width == 0 || fieldSize.height == 0) {
        return;
    }
    
    rect = CGRectInset(rect, 10, 10);
    
    // field calculations
    // разделили ширину и высоту вью 11 частей
    // мин чтобы квадрат был
    CGFloat cellWidth = floor(MIN(CGRectGetWidth(rect) / fieldSize.width,
                                  CGRectGetHeight(rect) / fieldSize.height));
    
                                  //             13   + (               622   -     56    *          11    ) / 2
    CGRect fieldRect = CGRectMake(CGRectGetMinX(rect) + (CGRectGetWidth(rect) - cellWidth * fieldSize.width) / 2,
                                  CGRectGetMinY(rect) + (CGRectGetHeight(rect) - cellWidth * fieldSize.height) / 2,
                                     // 56  *           11
                                  cellWidth * fieldSize.width,
                                  cellWidth * fieldSize.height);

    self.fieldRect = fieldRect;
    // 56 будем применять для вычисления коорд во вью из коорд в клетках
    self.cellSize = cellWidth;
    
    // field drawing
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 1.f);
    
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    
    // рисуем поле в клеточной системе
                                // 11 клеток
    for (int i = 0; i < fieldSize.width + 1; i++) {
        // строим вертик линии
        CGContextMoveToPoint(context, CGRectGetMinX(fieldRect) + cellWidth * i, CGRectGetMinY(fieldRect));
        CGContextAddLineToPoint(context, CGRectGetMinX(fieldRect) + cellWidth * i, CGRectGetMaxY(fieldRect));
    }
    
    for (int i = 0; i < fieldSize.height + 1; i++) {
        // строим гориз линии
        CGContextMoveToPoint(context, CGRectGetMinX(fieldRect), CGRectGetMinY(fieldRect) + cellWidth * i);
        CGContextAddLineToPoint(context, CGRectGetMaxX(fieldRect), CGRectGetMinY(fieldRect) + cellWidth * i);
    }
    
    // рисуем Path
    CGContextStrokePath(context);
    
    // robots drawing
    NSInteger robotsNumber = [self.dataSource numberOfRobotsOnBattleField:self];
    for (int i = 0; i < robotsNumber; i++) {
        
        // берем коор в клеточной системе
        CGRect robotRect = [self.dataSource battleField:self rectForRobotAtIndex:i];
        // высчитали координаты в системе вью
        robotRect = [self rectFromRelativeRect:robotRect];
        
        UIColor* robotColor = nil;
        
        if ([self.dataSource respondsToSelector:@selector(battleField:colorForRobotAtIndex:)]) {
            robotColor = [self.dataSource battleField:self colorForRobotAtIndex:i];
        }
        
        if (!robotColor) {
            robotColor = [UIColor blackColor];
        }
        
        CGContextSetFillColorWithColor(context, robotColor.CGColor);
        CGContextSetStrokeColorWithColor(context, robotColor.CGColor);
        
        // передали для окрашивания
        CGContextAddRect(context, robotRect);
        CGContextFillPath(context);
    }
    
    // shots drawing
    NSInteger shotsNumber = [self.dataSource numberOfShotsOnBattleField:self];
    for (int i = 0; i < shotsNumber; i++) {
        
        // коорд в клетках
        CGPoint shotCoord = [self.dataSource battleField:self shotCoordinateAtIndex:i];
        
        // коорд в вью
        CGRect rect = CGRectMake(CGRectGetMinX(fieldRect) + cellWidth * shotCoord.x,
                                 CGRectGetMinY(fieldRect) + cellWidth * shotCoord.y,
                                 cellWidth, cellWidth);
        
        BOOL hit = NO;
        
        for (int j = 0; j < robotsNumber; j++) {
            
            // коорд в клетках
            CGRect robotRect = [self.dataSource battleField:self rectForRobotAtIndex:j];
            
            if (CGRectContainsPoint(robotRect, shotCoord)) {
                // в зависимости от флажка будет цвет у shotCoord
                hit = YES;
                break;
            }
            
        }
        
        UIColor * color = hit ? [UIColor redColor] : [UIColor lightGrayColor];
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        
        // для рисования передали рект в коррд вью
        CGContextAddRect(context, rect);
        CGContextFillPath(context);
    }

    // text drawing
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(0, 2);
    shadow.shadowBlurRadius = 2;
    shadow.shadowColor = [UIColor blackColor];
    
    NSMutableParagraphStyle* paragraph = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
    
    for (int i = 0; i < robotsNumber; i++) {
        
        // коорд в клетках
        CGRect robotRect = [self.dataSource battleField:self rectForRobotAtIndex:i];
        // рект в коорд вью
        robotRect = [self rectFromRelativeRect:robotRect];
        
        NSString* name = [self.dataSource battleField:self nameForRobotAtIndex:i];
        
        NSDictionary* attributes =
        [NSDictionary dictionaryWithObjectsAndKeys: [UIFont systemFontOfSize:20.f], NSFontAttributeName,
                                                     [UIColor whiteColor],          NSStrokeColorAttributeName,
                                                     [UIColor whiteColor],          NSForegroundColorAttributeName,
                                                     shadow,                        NSShadowAttributeName,
                                                     paragraph,                     NSParagraphStyleAttributeName,
                                                     nil];
        // рисуем строку в ректе в коорд вью с аттрибутами
        [name drawInRect:robotRect withAttributes:attributes];
    }
    
}


@end



