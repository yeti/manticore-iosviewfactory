//
//  MCAppModel.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 3/15/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCIntent.h"
#import "MCConstants.h"

@interface MCViewModel : NSObject

// view
@property(atomic,retain) NSDictionary* errorDict;
@property(atomic,retain) MCIntent* currentSection; // rename to currentActivity
@property(atomic,retain) NSString* screenOverlay; // name of the screen overlay, naming convention of UIImage, may be suffixed by _5, do not include extension
@property(atomic,retain) NSArray* screenOverlays; // array of strings that name the screen overlays to show in succession, may be suffixed by _5, do not include extension
@property(atomic,retain) NSMutableArray* historyStack; // saved intents on the history stack. Do not change this variable directly.

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
