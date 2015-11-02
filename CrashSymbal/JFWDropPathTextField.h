//
//  JFWDropPathTextField.h
//  CrashSymbal
//
//  Created by Julian Weinert on 02/11/15.
//  Copyright © 2015 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol JFWDropPathDelegate;

@interface JFWDropPathTextField : NSTextField

@property (nonatomic, assign) IBOutlet id<JFWDropPathDelegate> pathDropDelegate;

@end

@protocol JFWDropPathDelegate <NSObject>

- (NSArray<NSString *> *)validFileTypesForDropPathTextField:(JFWDropPathTextField *)dropPathTextField;
- (void)dropPathTextField:(JFWDropPathTextField *)dropPathTextField didDropPath:(NSString *)path;

@end
