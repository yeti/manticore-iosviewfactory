//
//  MCAppModel.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 3/15/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCIntent.h"

#define STACK_SIZE_UNLIMITED 0
#define STACK_SIZE_DISABLED 1

@interface MCViewModel : NSObject

// view
@property(nonatomic,retain) NSDictionary* errorDict;
@property(nonatomic,retain) MCIntent* currentSection;
@property(nonatomic,retain) NSMutableArray* historyStack; // saved intents on the history stack

// valid settings are STACK_SIZE_DISABLED, STACK_SIZE_UNLIMITED, and > 0. Stack size includes the current view controller.
@property() int stackSize;

+(MCViewModel*)sharedModel;

// clear the history of intents
-(void)clearHistoryStack;

// clear the cached UIViewControllers created by MCMainViewController
-(void)clearViewCache;

// show an error message above the main window, does not affect the history stack
-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description;

@end
