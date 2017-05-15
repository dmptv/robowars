//
//  ASTarget.m
//  RoboWars
//
//  Created by Oleksii Skutarenko on 08.11.13.
//  Copyright (c) 2013 Alex Skutarenko. All rights reserved.
//

#import "ASTarget.h"

@implementation ASTarget

- (id) initWithRect:(CGRect) rect {
    self = [super init];
    if (self) {
        self.rect = rect;
        self.health = [NSMutableSet set];
        
        // проходим по прямоугольнику ректа
        // точки будем хранить в strings
        for (int i = CGRectGetMinX(self.rect); i < CGRectGetMaxX(self.rect); i++) {
            for (int j = CGRectGetMinY(self.rect); j < CGRectGetMaxY(self.rect); j++) {
                // берем origin каждой клетки
                CGPoint p = CGPointMake(i, j);
                // добавили в set как строку
                [self.health addObject:NSStringFromCGPoint(p)];
            }
        }
    }
    return self;
}

@end
