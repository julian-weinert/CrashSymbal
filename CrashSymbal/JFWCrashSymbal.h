//
//  JFWCrashSymbal.h
//  JFWCrashSymbal
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import <AppKit/AppKit.h>

@class JFWCrashSymbal;

static JFWCrashSymbal *sharedPlugin;

@interface JFWCrashSymbal : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle *bundle;
@end