//
//  ASViewController.m
//  RoboWars
//
//  Created by Oleksii Skutarenko on 13.10.13.
//  Copyright (c) 2013 Alex Skutarenko. All rights reserved.
//

#import "ASBattleViewController.h"
#import "ASBattleFieldView.h"
#import "ASTestPilot.h"
#import "RWPilot.h"
#import "ASRobot.h"
#import "ASPilot.h"

#import "AKUtils.h"

#import "ASSmart.h"

@interface ASBattleViewController () <ASBattleFieldDataSource>

@property (assign, nonatomic) CGSize fieldSize;
@property (strong, nonatomic) NSArray* allRobots;
@property (strong, nonatomic) NSMutableArray* selectedRobots;
@property (strong, nonatomic) NSMutableArray* shots;
@property (strong, nonatomic) NSMutableArray* robotsOrder;
@property (assign, nonatomic) BOOL shouldRestart;
@property (strong, nonatomic) NSMutableSet* buggyRobots;

@end

@implementation ASBattleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.buggyRobots = [NSMutableSet set];
    
    self.battleView.layer.borderWidth = 1.f;
    self.battleView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.battleView.layer.cornerRadius = 5.f;
    
    self.shots = [NSMutableArray array];
    self.robotsOrder = [NSMutableArray array];
    
    ASSmart* p1         = [[ASSmart alloc] init];
    ASTestPilot* p2     = [[ASTestPilot alloc] init];
    ASTestPilot* p3     = [[ASTestPilot alloc] init];
    ASTestPilot* p4     = [[ASTestPilot alloc] init];
    
    self.allRobots = [NSArray arrayWithObjects:
                      [ASRobot robotWithPilot:p1],
                      [ASRobot robotWithPilot:p2],
                      [ASRobot robotWithPilot:p3],
                      [ASRobot robotWithPilot:p4],
                      nil];
    
    self.allRobots = [self shuffleArray:self.allRobots];
    
    // по умолчанию все роботы выбраны
    self.selectedRobots = [NSMutableArray arrayWithArray:self.allRobots];
    
    self.battleView.dataSource = self;
    
    // создадим поле и расположим роботов
    [self randomizeField];
    
    [self.battleView reloadData];
    [self.tableView reloadData];
}


   // смешаем роботов
- (NSArray*) shuffleArray:(NSArray*) array {
    // будем перемешивать другой в другом массиве
    NSMutableArray* temp = [NSMutableArray arrayWithArray:array];
    
    int count = (int)[temp count] * 10;
    
    for (int i = 0; i < count; i++) {
        // возьмем остаток от деления i на [temp count]
        int index1 = i % [temp count];
         // возьмем остаток от деления рэндомного на [temp count]
        int index2 = arc4random() % [temp count];
        
        if (index1 != index2) {
            [temp exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
        }
        
    }
    return temp;
}

#pragma mark - Actions
- (void) randomizeField {
    // очистим все временные коллекции
    [self.robotsOrder removeAllObjects];
    [self.shots removeAllObjects];
    [self.buggyRobots removeAllObjects];
    
    // дадим размер поля имзменяемый в зависимости от кол-ва роботов
    self.fieldSize = CGSizeMake(7 + [self.selectedRobots count],
                                7 + [self.selectedRobots count]);
    
    NSMutableArray* selectedRects = [NSMutableArray array];
    
    // find a place for a robot
    for (ASRobot* robot in self.selectedRobots) {
        
         // передали роботу fieldSize равен 11 на 11 клеток
        robot.pilot.fieldSize = self.fieldSize;
        
        BOOL placeIsAvailable = NO;
        
        // будем заходить сюда повторно если tempRect или рект предыдущих роботов персесекаются
        while (!placeIsAvailable) {
            
            // установим размеры вертик 2х3 или горизон 3х2 роботы
            CGSize tempSize = arc4random() % 2 ? CGSizeMake(2,3) : CGSizeMake(3,2);
            
            // рэндомный origin на всю width или height поля минус width или height робота
            CGRect tempRect = CGRectMake(arc4random() % (int)(self.fieldSize.width - tempSize.width + 1),
                                         arc4random() % (int)(self.fieldSize.height - tempSize.height + 1),
                                         tempSize.width, tempSize.height);
            
            placeIsAvailable = YES;
            
            // вначале массив пустой и для первого робота мы не зашли в цикл
            // заходим для второго и далее роботов
            for (NSValue* value in selectedRects) {
                // взяли рект предыдущих роботов из массива
                CGRect selectedRect = [value CGRectValue];
                
                // проверяем если пересекаются ректы , то поставим флажок NO и еще раз попробуем дать
                if (CGRectIntersectsRect(selectedRect, tempRect)) {
                    placeIsAvailable = NO;
                    break;
                }
            }
            
            if (placeIsAvailable) {
                // ставим темп рект как окончательный рект робота
                robot.frame = tempRect;
                CGRect unavailableArea = CGRectInset(tempRect, -1, -1);
                // добавим в темп массив
                [selectedRects addObject:[NSValue valueWithCGRect:unavailableArea]];
            }
            
        }
        
        // create body parts
        NSMutableArray* health = [NSMutableArray array];
        for (int i = CGRectGetMinX(robot.frame); i < CGRectGetMaxX(robot.frame); i++) {
            for (int j = CGRectGetMinY(robot.frame); j < CGRectGetMaxY(robot.frame); j++) {
                [health addObject:[NSValue valueWithCGPoint:CGPointMake(i, j)]];
            }
        }
        robot.bodyParts = health;
        // при рестарте каждый робот обновит свой алгоритм
        [robot.pilot restart];  // protocol RWPilot
    }
    
    self.shouldRestart = [self.selectedRobots count] == 0;
    // обновим поле чтобы увидеть элементы
    [self.battleView reloadData];
}


- (void) nextMove {
    // если нет selectedRobots
    if (self.shouldRestart) {
        return;
    }
    
    if (![self.selectedRobots count]) {
        NSLog(@"No robots to fight");
        return;
    }
    
    if (![self.robotsOrder count]) {
        NSLog(@"NEXT TURN");
        
        NSMutableArray* tempRobots = [NSMutableArray array];
        for (ASRobot* robot in self.selectedRobots) {
            if ([robot.bodyParts count]) {
                [tempRobots addObject:robot];
            }
        }
        
        while ([tempRobots count] > 0) {
            
            NSInteger index = 0;
            if ([tempRobots count] > 1) {
                index = arc4random() %[tempRobots count];
            }
            
            [self.robotsOrder addObject:[tempRobots objectAtIndex:index]];
            [tempRobots removeObjectAtIndex:index];
        }
    }
    
    ASRobot* shootingRobot = [self.robotsOrder firstObject];
    
    /*
    if ([shootingRobot.pilot isKindOfClass:[ASTestPilot class]]) {
        [self.robotsOrder removeObjectAtIndex:0];
        [self nextMove];
        return;
    }
     */
    
    ASPilot* pilotCopy = [[ASPilot alloc] init];
    pilotCopy.name = [shootingRobot.pilot robotName];
    
    CGPoint coordinate = CGPointMake(-100, -100);
    
    @try {
        coordinate = [shootingRobot.pilot fire];  // protocol RWPilot
    }
    @catch (NSException *exception) {
        NSLog(@"EXCEPTION BECAUSE OF %@ WHEN HE WAS TRYING TO FIRE", [shootingRobot.pilot robotName]);
        NSLog(@"%@", exception);
        [self.buggyRobots addObject:shootingRobot];
        [self.robotsOrder removeObjectAtIndex:0];
        return;
    }
    @finally {}
    
    [self.shots addObject:[NSValue valueWithCGPoint:coordinate]];
    
    NSLog(@"%@ fires at %@", shootingRobot.name, NSStringFromCGPoint(coordinate));
    
    [self.battleView animateShotTo:coordinate fromRect:shootingRobot.frame];
    
    RWShotResult result = RWShotResultMiss;
    
    ASRobot* killedRobot = nil;
    for (ASRobot* robot in self.selectedRobots) {
        
        for (int i = 0; i < [robot.bodyParts count]; i++) {
            
            NSValue* cell = [robot.bodyParts objectAtIndex:i];
            
            if (CGPointEqualToPoint(coordinate, [cell CGPointValue])) {
                [robot.bodyParts removeObjectAtIndex:i];
                
                if ([robot.bodyParts count]) {
                    result = RWShotResultHit;
                } else {
                    result = RWShotResultDestroy;
                    
                    @try {
                        [robot.pilot shotFrom:pilotCopy withCoordinate:coordinate andResult:result]; // protocol RWPilot
                    }
                    @catch (NSException *exception) {
                        NSLog(@"EXCEPTION BECAUSE OF %@ WHEN HE GOT COORDINATES OF SHOT", [robot.pilot robotName]);  // protocol RWPilot
                        NSLog(@"%@", exception);
                        [self.buggyRobots addObject:robot];
                    }
                    @finally {}
                    
                    killedRobot = robot;
                }
                break;
            }
        }
        
        if (result != RWShotResultMiss) {
            break;
        }
    }
    
    for (ASRobot* robot in self.selectedRobots) {
        if ([robot.bodyParts count]) {
            
            @try {
                [robot.pilot shotFrom:pilotCopy withCoordinate:coordinate andResult:result];  // protocol RWPilot
            }
            @catch (NSException *exception) {
                NSLog(@"EXCEPTION BECAUSE OF %@ WHEN HE GOT COORDINATES OF SHOT", [robot.pilot robotName]);  // protocol RWPilot
                NSLog(@"%@", exception);
                [self.buggyRobots addObject:robot];
            }
            @finally {}
        }
    }
    
    [self.robotsOrder removeObjectAtIndex:0];
    
    if (killedRobot) {
        [self.robotsOrder removeObject:killedRobot];
        
        NSInteger aliveRobots = 0;
        ASRobot* winner = nil;
        for (ASRobot* robot in self.selectedRobots) {
            
            if ([robot.bodyParts count]) {
                aliveRobots++;
                winner = robot;
            }
            
        }
        
        if (aliveRobots == 1) {
            NSLog(@"Game is over! %@ is the winner!!!", winner.name);
            
            NSString* finalMessage = nil;
            
            if ([winner.pilot respondsToSelector:@selector(victoryPhrase)]) {
                finalMessage = [winner.pilot victoryPhrase];  // protocol RWPilot
            }
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ is the winner!", winner.name]
                                        message:finalMessage
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            
            self.shouldRestart = YES;
            
        } else {
            
            NSString* finalMessage = nil;
            
            if ([killedRobot.pilot respondsToSelector:@selector(defeatPhrase)]) {
                finalMessage = [killedRobot.pilot defeatPhrase];  // protocol RWPilot
            }
            /*
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ is destroyed", killedRobot.name]
                                        message:finalMessage
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
             */
        }
    }
}

- (IBAction) actionNewGame:(id)sender {
    [self randomizeField];
    [self.battleView reloadData];
}

- (IBAction) actionMove:(id)sender {
    [self nextMove];
}

#pragma mark - ASBattleFieldDataSource

- (CGSize) sizeForBattleField:(ASBattleFieldView*) battleField {
    return self.fieldSize;
}

- (NSInteger) numberOfRobotsOnBattleField:(ASBattleFieldView*) battleField {
    return [self.selectedRobots count];
}

- (CGRect) battleField:(ASBattleFieldView*) battleField rectForRobotAtIndex:(NSInteger) index {
    return [[[self.selectedRobots objectAtIndex:index] pilot] robotRect];
}

- (NSString*) battleField:(ASBattleFieldView *)battleField nameForRobotAtIndex:(NSInteger)index {
    return [[self.selectedRobots objectAtIndex:index] name];
}

- (NSInteger) numberOfShotsOnBattleField:(ASBattleFieldView*) battleField {
    return [self.shots count];
}

- (CGPoint) battleField:(ASBattleFieldView*) battleField shotCoordinateAtIndex:(NSInteger) index {
    return [[self.shots objectAtIndex:index] CGPointValue];
}

- (UIColor*) battleField:(ASBattleFieldView*) battleField colorForRobotAtIndex:(NSInteger) index {
    UIColor* color = [UIColor blackColor];
    
    if (index < [self.selectedRobots count]) {
        ASRobot* robot = [self.selectedRobots objectAtIndex:index];
        
        if ([self.buggyRobots containsObject:robot]) {
            color = [UIColor purpleColor];
        }
        
    }
    
    
    return color;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allRobots count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"Robot";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    ASRobot* robot = [self.allRobots objectAtIndex:indexPath.row];
    
    cell.textLabel.text = robot.name;
    cell.detailTextLabel.text = NSStringFromClass([robot.pilot class]);
    cell.accessoryType = [self.selectedRobots containsObject:robot] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    ASRobot* robot = [self.allRobots objectAtIndex:indexPath.row];
    
    if ([self.selectedRobots containsObject:robot]) {
        [self.selectedRobots removeObject:robot];
    } else {
        [self.selectedRobots addObject:robot];
    }
    
    [tableView reloadData];
    [self randomizeField];
}

@end








