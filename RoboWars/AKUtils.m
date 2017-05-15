//
//  AKUtils.m
//  RoboWars
//
//  Created by Kanat A on 21/02/2017.
//  Copyright © 2017 Alex Skutarenko. All rights reserved.
//

#import "AKUtils.h"
#import <UIKit/UIKit.h>


void AKLog(NSString* format, ...) {
    
#if LOGS_ENABLED
    
    va_list argumentList;
    va_start(argumentList, format);
    
    NSLogv(format, argumentList);
        
    va_end(argumentList);
    
    
#endif
    
    
}
