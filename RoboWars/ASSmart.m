//
//  ASSmart.m
//  RoboWars
//
//  Created by Oleksii Skutarenko on 08.11.13.
//  Copyright (c) 2013 Alex Skutarenko. All rights reserved.
//

#import "ASSmart.h"
#import "ASTarget.h"

@interface ASSmart ()

@property (strong, nonatomic) NSMutableArray* targets;

@end

@implementation ASSmart

#pragma mark - Help Functions

    // создадим массив всех возможных таргетов
- (NSArray*) arrayOfTargetsWithSize:(CGSize) size
                      excludingRect:(CGRect) excludingRect
                    inFieldWithSize:(CGSize) fieldSize {
    
    NSMutableArray* array = [NSMutableArray array];
    
    // пройдем по полю найдем все возможные таргеты                                                           // ***
    for (int i = 0; i <= fieldSize.width - size.width; i++) {
        for (int j = 0; j <= fieldSize.height - size.height; j++) {
            
            CGRect rect = CGRectMake(i, j, size.width, size.height);
            
            // если рект не пересекается с self ректом , то создадим таргет
            if (!CGRectIntersectsRect(excludingRect, rect)) {
                
                ASTarget* target = [[ASTarget alloc] initWithRect:rect];
                
                [array addObject:target];
            }
        }
    }
    
    return array;
}

    // при промахе
- (void) missAtCoordinate:(CGPoint) coordinate {
    
    // убираем таргеты при промахе
    // при удалении объекта из массив проход в обратном порядке i--
    for (int i = (int)[self.targets count] - 1; i >= 0; i--) {
        ASTarget* target = [self.targets objectAtIndex:i];
        
        if (CGRectContainsPoint(target.rect, coordinate)) {
            
            // если промах входит в таргет, тогда убираем
            [self.targets removeObject:target];
        }
        
    }
    
}

    // если попали
- (void) hitAtCoordinate:(CGPoint) coordinate {
    
    // сделаем строку из выстрела
    NSString* hp = NSStringFromCGPoint(coordinate);
    // флажок для проверки
    CGRect destroyedRect = CGRectZero;
    
    for (int i = (int)[self.targets count] - 1; i >= 0; i--) {
        ASTarget* target = [self.targets objectAtIndex:i];
        
        // если таргет содержит строку выстрела
        if ([target.health containsObject:hp]) {
            [target.health removeObject:hp];
            
            // если здоровье стало 0, убит
            if ([target.health count] == 0) {
                // чтобы не вызывать метод сделали сохранение ректа для проверки
                destroyedRect = target.rect;
                [self.targets removeObjectAtIndex:i];
            }
        }
    }
    
    // проверим и вызовем метод
    if (!CGRectIsEmpty(destroyedRect)) {
        [self targetDestroyedAtRect:destroyedRect];
    }
}

   // обстреляем вокруг уничтоженного таргета
- (void) targetDestroyedAtRect:(CGRect) rect {
    
    rect = CGRectInset(rect, -1, -1);
    // сделаем рект поля
    CGRect fieldRect = CGRectZero;
    fieldRect.size = self.fieldSize;
    
    // проходим по всем клеткам убитого таргета
    for (int i = CGRectGetMinX(rect); i < CGRectGetMaxX(rect); i++) {
        for (int j = CGRectGetMinY(rect); j < CGRectGetMaxY(rect); j++) {
            
            CGPoint p = CGPointMake(i, j);
            
            // проверка что клетки находятся на поле , не выходят за край
            if (CGRectContainsPoint(fieldRect, p)) {
                // симулируем промах
                [self missAtCoordinate:p];
            }
            
        }
    }
}

     // ищем таргеты с наименьшим здоровьем
- (NSArray*) lessHealthTargets {

    // если нет таргетов или остался последний таргет
    if ([self.targets count] <= 1) {
        return self.targets;
    }
    
    // это не копия. а другой массив
    NSMutableArray* array = [NSMutableArray arrayWithArray:self.targets];
    
    // отсортируем массив
    // получим Ascending
    [array sortUsingComparator:^NSComparisonResult(ASTarget* obj1, ASTarget* obj2) {
        
        if ([obj1.health count] < [obj2.health count]) {
            return NSOrderedAscending;
        } else if ([obj1.health count] > [obj2.health count]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
        
    }];
    
    NSMutableArray* resultArray = [NSMutableArray array];
    NSInteger minHealth = NSIntegerMax;
    
    // соберем все таргеты с мин здороьвем ***
    for (ASTarget* target in array) {
        
        if ([target.health count] <= minHealth) {
            // теперь minHealth будет равен первому таргету с мин здоровьем
            minHealth = [target.health count];
            // в самом начале все возможные таргеты придут 
            [resultArray addObject:target];
        } else {
            break;
        }
        
    }
    
    return resultArray;
}

    // найдем где больше всего возможных ректов из всех возможных таргетов
    // проверим совпадают ли координаты helth таргетов
- (NSArray*) bestHitChanceCoordinatesFromTargets:(NSArray*) targets {
    // targets - это таргеты с наименьшим здоровьем
    
    // если таргетов нет
    if ([targets count] == 0) {
        
        return nil;
        
    } else if ([targets count] == 1) {
        
        // если один таргет
        ASTarget* target = [targets firstObject];
        
        // значит все его координаты подходят для выстрела
        return [target.health allObjects];
    }
    
    // запишем в дикшэнри каждую координату как ключ и значение = 1,
    // если в другом таргете получится достать значение по какой то координате ,
    // то увеличим ее значение на 1
    
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    for (ASTarget* target in targets) {
        
        // пройдем по массиву всех точек и запишем в дикшэнри значение по ключю
        NSArray* coords = [target.health allObjects];                    // ***
        // все точки это ключи
        for (NSString* key in coords) {
            
            // попытаемся взять value из пустого дикшэни по этому ключю (точке)
            NSNumber* number = [dictionary objectForKey:key];
            
            if (!number) {
                // если value нет , то создадим value = 1
                number = [NSNumber numberWithInteger:1];
            } else {
                // если есть value, то увеличим его на 1
                NSInteger current = [number integerValue];
                number = [NSNumber numberWithInteger:current + 1];
            }
            
            [dictionary setObject:number forKey:key];
        }
    }
    
    if ([dictionary count] == 0) {
        
        return nil;
        
    } else if ([dictionary count] == 1) {
        
        // если у таргета остался 1 здоровье (ключ), вернем его
        return [dictionary allKeys];
    }
    
    // ключи будут отсортированы по значениям
    // c большим value будут в конце массива
    
    NSArray* sortedCoords = [dictionary keysSortedByValueUsingComparator:
                             ^NSComparisonResult(NSNumber* obj1, NSNumber* obj2) {
                                 
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray* resultArray = [NSMutableArray array];
    NSInteger maxNumber = 0;
    
    // пройдем массив с конца, чтобы выбрать коорд(ключи) у которых больше совпадений(value)
    
    for (int i = (int)[sortedCoords count] - 1; i >= 0; i--) {
        
        NSString* key = [sortedCoords objectAtIndex:i];
        NSNumber* number = [dictionary objectForKey:key];
        
        // возьмем первый же большой number и если есть другие такие же
        
        if ([number integerValue] >= maxNumber) {                   // ***
            
            // assing
            maxNumber = [number integerValue];
            [resultArray addObject:key];
            
        } else {
            break;
        }
        
    }
    
    return resultArray;
}


#pragma mark - RWPilot

- (void) restart {
    // при рестарте каждый робот обновит свой алгоритм
    
    // заполним массив таргетов
    // init
    self.targets = [NSMutableArray array];
    
    // робот с отступом вокруг него
    CGRect selfArea = CGRectInset(self.robotRect, -1, -1);
    
    CGFloat minSize = MIN(CGRectGetWidth(self.robotRect), CGRectGetHeight(self.robotRect));
    CGFloat maxSize = MAX(CGRectGetWidth(self.robotRect), CGRectGetHeight(self.robotRect));
    
    // создадим таргеты
    NSArray* verticalTargets = [self arrayOfTargetsWithSize:CGSizeMake(minSize, maxSize)
                                              excludingRect:selfArea
                                            inFieldWithSize:self.fieldSize];
    
    NSArray* horizontalTargets = [self arrayOfTargetsWithSize:CGSizeMake(maxSize, minSize)
                                                excludingRect:selfArea
                                              inFieldWithSize:self.fieldSize];
    
    [self.targets addObjectsFromArray:verticalTargets];
    [self.targets addObjectsFromArray:horizontalTargets];
}

- (CGPoint) fire {
    // для встрела найдем самых слабых и
    // с наибольшим совпадение возможных таргетов координаты
    
    NSArray* minHealthTargets = [self lessHealthTargets];
    // найдем где больше таргетов
    NSArray* coordinatesToFire = [self bestHitChanceCoordinatesFromTargets:minHealthTargets];
    
    // если не нашли координаты
    if ([coordinatesToFire count] == 0) {
        NSLog(@"Cannot shoot :(");
        // выстрел в несуществующиую точку
        return CGPointMake(-10, -10);
    }
    
    // возьмем первую точку
    NSString* stringCoord = [coordinatesToFire firstObject];
    
    return CGPointFromString(stringCoord);
}

- (NSString*) robotName {
    return @"Smart";
}

     // те мы стреляем и нам приходит result выстрела
- (void) shotFrom:(id<RWPilot>) robot withCoordinate:(CGPoint) coordinate andResult:(RWShotResult) result {
    
    // result приходит от контроллера
    if (result == RWShotResultMiss) {
        [self missAtCoordinate:coordinate];
    } else {
        [self hitAtCoordinate:coordinate];
    }
}

- (NSString*) victoryPhrase {
    return @"I am the winner!";
}


- (NSString*) defeatPhrase {
    return @"Goodbye guys!";
}


@end






