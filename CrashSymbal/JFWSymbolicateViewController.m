//
//  JFWSymbolicateViewController.m
//  CrashSymbol
//
//  Created by Julian Weinert on 01/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import "JFWSymbolicateViewController.h"
#import "DVTFontAndColorTheme.h"

@interface JFWSymbolicateViewController ()

@property (nonatomic, assign) IBOutlet NSTextField *pathTextField;
@property (nonatomic, assign) IBOutlet NSTextView *outputView;

@property (nonatomic, assign) IBOutlet NSButton *openButton;
@property (nonatomic, assign) IBOutlet NSButton *exportButton;
@property (nonatomic, assign) IBOutlet NSButton *symbolicateButton;
@property (nonatomic, assign) IBOutlet NSButton *closeWindowButton;
@property (nonatomic, assign) IBOutlet NSButton *popOutWindowButton;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressBar;

@property (nonatomic, retain) IBOutlet NSView *openAccessoryView;
@property (nonatomic, retain) IBOutlet NSView *saveAccessoryView;

@property (nonatomic, retain) IBOutlet NSButton *openAccessoryShowHiddenCheckbox;
@property (nonatomic, retain) IBOutlet NSButton *saveAccessoryShowHiddenCheckbox;
@property (nonatomic, retain) IBOutlet NSButton *saveAccessoryRevealInFinderCheckbox;

@property (nonatomic, retain) NSString *selectedPath;
@property (nonatomic, retain) NSMutableString *symbolicatedCrash;

@property (nonatomic, assign) NSOpenPanel *openPanel;
@property (nonatomic, assign) NSSavePanel *savePanel;

@end

@implementation JFWSymbolicateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	Class DVTFontAndColorThemeClass = NSClassFromString(@"DVTFontAndColorTheme");
	DVTFontAndColorTheme *currentTheme = [DVTFontAndColorThemeClass currentTheme];
	
	[[self outputView] setRichText:NO];
	[[self outputView] setFont:[currentTheme consoleDebuggerOutputTextFont]];
	[[self outputView] setTextColor:[currentTheme consoleDebuggerOutputTextColor]];
	[[self outputView] setBackgroundColor:[currentTheme consoleTextBackgroundColor]];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ([userDefaults boolForKey:@"de.julianweinert.JFWCrashSymbal.openPanelShowHidden"]) {
		[[self openAccessoryShowHiddenCheckbox] setState:NSOnState];
	}
	if ([userDefaults boolForKey:@"de.julianweinert.JFWCrashSymbal.savePanelShowHidden"]) {
		[[self saveAccessoryShowHiddenCheckbox] setState:NSOnState];
	}
	if ([userDefaults boolForKey:@"de.julianweinert.JFWCrashSymbal.savePanelReveal"]) {
		[[self saveAccessoryRevealInFinderCheckbox] setState:NSOnState];
	}
}

- (void)viewWillAppear {
	[super viewWillAppear];
	
	if ([[[self windowController] window] sheetParent]) {
		[[self popOutWindowButton] setHidden:NO];
	}
	else {
		[[self popOutWindowButton] setHidden:YES];
		[[self closeWindowButton] setTitle:@"Close"];
	}
}

#pragma mark - property accessor overrides

- (void)setSelectedPath:(NSString *)selectedPath {
	if (selectedPath != _selectedPath && [selectedPath length] > 0 && [[selectedPath pathExtension] isEqualToString:@"crash"]) {
		_selectedPath = selectedPath;
		
		[[self pathTextField] setStringValue:selectedPath];
		[[self symbolicateButton] setEnabled:YES];
		[[self progressBar] setDoubleValue:0];
		[[self exportButton] setEnabled:NO];
	}
}

#pragma mark - implementation

- (IBAction)closeWindow:(id)sender {
	if ([[[self windowController] window] sheetParent]) {
		[[[[self windowController] window] sheetParent] endSheet:[[self windowController] window] returnCode:NSModalResponseOK];
	}
	else {
		[[self windowController] close];
	}
}

- (IBAction)popOutButWindow:(id)sender {
	[[[[self windowController] window] sheetParent] endSheet:[[self windowController] window] returnCode:NSModalResponseContinue];
}

- (IBAction)selectFile:(id)sender {
	[self setOpenPanel:[NSOpenPanel openPanel]];
	
	[[self openPanel] setShowsHiddenFiles:[[self openAccessoryShowHiddenCheckbox] state] == NSOnState];
	[[self openPanel] setAccessoryView:[self openAccessoryView]];
	[[self openPanel] setAllowedFileTypes:@[@"crash"]];
	[[self openPanel] setCanSelectHiddenExtension:YES];
	[[self openPanel] setAllowsMultipleSelection:NO];
	[[self openPanel] setCanCreateDirectories:YES];
	[[self openPanel] setAllowsOtherFileTypes:NO];
	[[self openPanel] setCanChooseDirectories:NO];
	[[self openPanel] setCanChooseFiles:YES];
	
	[[self openPanel] beginSheetModalForWindow:[[self windowController] window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[self setSelectedPath:[[[self openPanel] URL] path]];
		}
	}];
}

- (IBAction)symbolicate:(id)sender {
	if ([self selectedPath]) {
		[[self outputView] setString:@""];
		
		[[self openButton] setEnabled:NO];
		[[self symbolicateButton] setEnabled:NO];
		[[self progressBar] setIndeterminate:YES];
		
		[self setSymbolicatedCrash:[NSMutableString string]];
		
		dispatch_async(dispatch_queue_create("de.julianweinert.CrashSymbal.symbolicate", 0), ^{
			NSPipe *stdOutPipe = [NSPipe pipe];
			NSPipe *stdErrPipe = [NSPipe pipe];
			
			NSFileHandle *stdOut = [stdOutPipe fileHandleForReading];
			NSFileHandle *stdErr = [stdErrPipe fileHandleForReading];
			
			void (^appendToLog)(NSString *) = ^(NSString *string) {
				dispatch_sync(dispatch_get_main_queue(), ^{
					BOOL scroll = [string length] > 0;//(NSMaxY([[self outputView] visibleRect]) == NSMaxY([[self outputView] bounds]));
					
					[[self outputView] setString:[[[self outputView] string] stringByAppendingString:string]];
					
					if (scroll) {
						[[self outputView] scrollRangeToVisible:NSMakeRange([[[self outputView] string] length], 0)];
					}
				});
			};
			
			[stdOut setReadabilityHandler:^(NSFileHandle *fileHandle) {
				NSData *outData = [fileHandle availableData];
				
				if (outData) {
					NSStringEncoding outEncoding = [NSString stringEncodingForData:outData encodingOptions:nil convertedString:nil usedLossyConversion:nil];
					NSString *outString = [[NSString alloc] initWithData:outData encoding:outEncoding];
					
					appendToLog(outString);
					[[self symbolicatedCrash] appendString:outString];
				}
			}];
			
			[stdErr setReadabilityHandler:^(NSFileHandle *fileHandle) {
				NSData *errData = [fileHandle availableData];
				
				if (errData) {
					NSStringEncoding errEncoding = [NSString stringEncodingForData:errData encodingOptions:nil convertedString:nil usedLossyConversion:nil];
					NSString *errString = [[NSString alloc] initWithData:errData encoding:errEncoding];
					
					appendToLog(errString);
				}
			}];
			
			NSString *developerDir = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Developer"];
			
			NSTask *symbolicationTask = [[NSTask alloc] init];
			[symbolicationTask setLaunchPath:[[NSBundle bundleWithIdentifier:@"com.apple.DTDeviceKitBase"] pathForResource:@"symbolicatecrash" ofType:nil]];
			[symbolicationTask setEnvironment:@{@"DEVELOPER_DIR": developerDir}];
			[symbolicationTask setArguments:@[@"-v", [self selectedPath]]];
			[symbolicationTask setStandardOutput:stdOutPipe];
			[symbolicationTask setStandardError:stdErrPipe];
			[symbolicationTask launch];
			
			[symbolicationTask waitUntilExit];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self symbolicationDone];
			});
		});
	}
}

- (IBAction)exportLog:(id)sender {
	NSString *fileName = [[self selectedPath] lastPathComponent];
	fileName = [[[fileName stringByDeletingPathExtension] stringByAppendingString:@"_symbolicated"] stringByAppendingPathExtension:[fileName pathExtension]];
	
	[self setSavePanel:[NSSavePanel savePanel]];
	
	[[self savePanel] setShowsHiddenFiles:[[self saveAccessoryShowHiddenCheckbox] state] == NSOnState];
	[[self savePanel] setMessage:@"Select a location for the symbolicated crash log."];
	[[self savePanel] setAccessoryView:[self saveAccessoryView]];
	[[self savePanel] setNameFieldStringValue:fileName];
	[[self savePanel] setCanCreateDirectories:YES];
	
	[[self savePanel] beginSheetModalForWindow:[[self windowController] window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[[[self symbolicatedCrash] dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[[self savePanel] URL] atomically:YES];
			
			if ([[self saveAccessoryRevealInFinderCheckbox] state] == NSOnState) {
				NSURL *fileURL = [[[self savePanel] URL] copy];
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
				});
			}
		}
	}];
}

- (IBAction)openAcceccoryShowHidden:(NSButton *)sender {
	[[self openPanel] setShowsHiddenFiles:[sender state] == NSOnState];
	
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] == NSOnState forKey:@"de.julianweinert.JFWCrashSymbal.openPanelShowHidden"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)saveAccessoryShowHidden:(NSButton *)sender {
	[[self savePanel] setShowsHiddenFiles:[sender state] == NSOnState];
	
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] == NSOnState forKey:@"de.julianweinert.JFWCrashSymbal.savePanelShowHidden"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)saveAccessoryReveal:(NSButton *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] == NSOnState forKey:@"de.julianweinert.JFWCrashSymbal.savePanelReveal"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - internal implementation

- (void)symbolicationDone {
	[[self exportButton] setEnabled:[[self symbolicatedCrash] length] > 0];
	[[self symbolicateButton] setEnabled:YES];
	[[self openButton] setEnabled:YES];
	
	[[self progressBar] setIndeterminate:NO];
	[[self progressBar] setDoubleValue:100];
}

@end
