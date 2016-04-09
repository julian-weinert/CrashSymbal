//
//  JFWSymbolicateViewController.h
//  CrashSymbol
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JFWSymbolicateViewController : NSViewController

@property (nonatomic, assign) NSWindowController *windowController;

NSString * symbPathForIdentifier(NSString *identifier);

@end
