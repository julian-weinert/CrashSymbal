//
//  JFWCrashSymbal.m
//  JFWCrashSymbal
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import "JFWCrashSymbal.h"
#import "JFWSymbolicateViewController.h"

@interface JFWCrashSymbal() <NSUserInterfaceValidations>

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, retain) NSMenuItem *symbolicationMenuItem;
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

- (void)applicationDidFinishLaunching:(NSNotification *)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
	
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Debug"];
	
    if (menuItem) {
		NSString *itemTitle = @"Symbolicate Crashlog...";
		
		if (!(symbPathForIdentifier(@"com.apple.dt.DVTFoundation") ?: symbPathForIdentifier(@"com.apple.DTDeviceKitBase"))) {
			itemTitle = [itemTitle stringByAppendingString:@"  (incompatible)"];
		}
		
		[self setSymbolicationMenuItem:[[NSMenuItem alloc] initWithTitle:itemTitle action:@selector(openSymbolicationPanel:) keyEquivalent:@""]];
		[[self symbolicationMenuItem] setTarget:self];
		
		[[menuItem submenu] addItem:[NSMenuItem separatorItem]];
		[[menuItem submenu] addItem:[self symbolicationMenuItem]];
    }
}

- (void)openSymbolicationPanel:(id)sender {
	if (!(symbPathForIdentifier(@"com.apple.dt.DVTFoundation") ?: symbPathForIdentifier(@"com.apple.DTDeviceKitBase"))) {
		[NSApp presentError:[[NSError alloc] initWithDomain:[[NSBundle mainBundle] bundleIdentifier]
													   code:404
												   userInfo:@{
														   NSLocalizedDescriptionKey: @"Xcode incompatible!",
														   NSLocalizedRecoverySuggestionErrorKey: @"Could not find `symbolicatecrash`.\nPlease run a different version of Xcode or discuss the absence of symbolicatecrash with the community."
														   }]];
		
		return;
	}
	
	[self setSymbolicateWindowController:[[NSStoryboard storyboardWithName:@"JFWSymbolicate" bundle:[self bundle]] instantiateInitialController]];
	[(JFWSymbolicateViewController *)[[self symbolicateWindowController] contentViewController] setWindowController:[self symbolicateWindowController]];
	
	if ([NSApp mainWindow]) {
		[[NSApp mainWindow] beginSheet:[[self symbolicateWindowController] window] completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSModalResponseContinue) {
				[[self symbolicateWindowController] performSelector:@selector(showWindow:) withObject:sender afterDelay:0.0];
			}
			else {
				[self setSymbolicateWindowController:nil];
			}
		}];
	}
	else {
		[[self symbolicateWindowController] showWindow:sender];
	}
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
//	if (anItem == [self symbolicationMenuItem]) {
//		if (![NSApp mainWindow]) {
//			return NO;
//		}
//	}
	return YES;
}

@end
