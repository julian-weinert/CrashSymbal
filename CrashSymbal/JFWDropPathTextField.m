//
//  JFWDropPathTextField.m
//  CrashSymbal
//
//  Created by Julian Weinert on 02/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import "JFWDropPathTextField.h"

@implementation JFWDropPathTextField

- (void)awakeFromNib {
	[super awakeFromNib];
	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
		if ([sender draggingSourceOperationMask] & NSDragOperationCopy) {
			NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
			
			if ([self firstValidPathInPaths:files]) {
				return NSDragOperationCopy;
			}
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	NSString *filePath = [self firstValidPathInPaths:files];
	
	if (filePath) {
		if ([[self pathDropDelegate] respondsToSelector:@selector(dropPathTextField:didDropPath:)]) {
			[[self pathDropDelegate] dropPathTextField:self didDropPath:filePath];
		}
		
		return YES;
	}
	
	return NO;
}

- (NSString *)firstValidPathInPaths:(NSArray<NSString *> *)paths {
	NSArray *validTypes;
	
	if ([[self pathDropDelegate] respondsToSelector:@selector(validFileTypesForDropPathTextField:)]) {
		validTypes = [[self pathDropDelegate] validFileTypesForDropPathTextField:self];
	}
	else {
		return [paths firstObject];
	}
	
	for (NSString *crashPath in paths) {
		NSString *pathExtension = [crashPath pathExtension];
		
		for (NSString *fileType in validTypes) {
			if ([pathExtension isEqualToString:fileType]) {
				return crashPath;
			}
		}
	}
	
	return nil;
}

@end
