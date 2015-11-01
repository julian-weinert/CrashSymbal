//
//  NSObject_Extension.m
//  CrashSymbol
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//


#import "NSObject_Extension.h"
#import "CrashSymbol.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[CrashSymbol alloc] initWithBundle:plugin];
        });
    }
}
@end
