//
//  JFWCrashSymbal.m
//  JFWCrashSymbal
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import "JFWCrashSymbal.h"
#import "JFWSymbolicateViewController.h"

@interface JFWCrashSymbal()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, retain) NSWindowController *symbolicateWindowController;

@end

@implementation JFWCrashSymbal

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
		[self setBundle:plugin];
		
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
	
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Debug"];
	
    if (menuItem) {
		NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Symbolicate Crashlog..." action:@selector(openSymbolicationPanel:) keyEquivalent:@""];
		[actionMenuItem setTarget:self];
		
		[[menuItem submenu] addItem:[NSMenuItem separatorItem]];
		[[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)openSymbolicationPanel:(id)sender {
	[self setSymbolicateWindowController:[[NSStoryboard storyboardWithName:@"JFWSymbolicate" bundle:[self bundle]] instantiateInitialController]];
	[(JFWSymbolicateViewController *)[[self symbolicateWindowController] contentViewController] setWindowController:[self symbolicateWindowController]];
	
	[[NSApp mainWindow] beginSheet:[[self symbolicateWindowController] window] completionHandler:^(NSModalResponse returnCode) {
		[self setSymbolicateWindowController:nil];
	}];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
