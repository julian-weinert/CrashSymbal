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

@property (nonatomic, assign) IBOutlet NSButton *exportButton;
@property (nonatomic, assign) IBOutlet NSButton *symbolicateButton;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressBar;

@property (nonatomic, retain) NSString *selectedPath;
@property (nonatomic, retain) NSMutableString *symbolicatedCrash;

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
	[[[[self windowController] window] sheetParent] endSheet:[[self windowController] window] returnCode:NSModalResponseOK];
}

- (IBAction)selectFile:(id)sender {
	NSOpenPanel *filePanel = [NSOpenPanel openPanel];
	
	[filePanel setMessage:@"Select a crash log to symbolicate..."];
	[filePanel setAllowedFileTypes:@[@"crash"]];
	[filePanel setCanSelectHiddenExtension:YES];
	[filePanel setAllowsMultipleSelection:NO];
	[filePanel setAllowsOtherFileTypes:NO];
	[filePanel setCanChooseDirectories:NO];
	[filePanel setCanChooseFiles:YES];
	
	[filePanel beginSheetModalForWindow:[[self windowController] window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[self setSelectedPath:[[filePanel URL] path]];
		}
	}];
}

- (IBAction)symbolicate:(id)sender {
	if ([self selectedPath]) {
		[[self outputView] setString:@""];
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
	
}

#pragma mark - internal implementation

- (void)symbolicationDone {
	[[self symbolicateButton] setEnabled:YES];
	[[self progressBar] setIndeterminate:NO];
	[[self progressBar] setDoubleValue:100];
	[[self exportButton] setEnabled:YES];
}

@end
