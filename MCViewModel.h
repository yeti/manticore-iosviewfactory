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

// Pointer to the error dictionary
@property(atomic, strong) NSDictionary      *errorDict;

// Pointer to the current intent
@property(atomic, strong) MCIntent          *currentIntent;

// Name of the screen overlay : naming convention of UIImage. Do not include extension.
// May be suffixed by _5 for iPhone 5 screen size overlay.
@property(atomic, strong) NSString          *screenOverlay;

// Array of strings for multiple overlays. Naming convention of UIImage. Do not include extension.
// May be suffixed by _5 for iPhone 5 screen size overlay.
@property(atomic, strong) NSArray           *screenOverlays;

// Saved intents on the history stack. Do not change this variable directly.
@property(atomic, strong) NSMutableArray    *historyStack;

// Valid settings are STACK_SIZE_DISABLED, STACK_SIZE_UNLIMITED, and > 0.
// Stack size includes the current view controller.
@property() int stackSize;


//--------------------------------------------------------------------------------
// Singleton Object
//
+ (MCViewModel * )sharedModel;


//--------------------------------------------------------------------------------
// Clear the history of intents
//
- (void)clearHistoryStack;


//--------------------------------------------------------------------------------
// Clear the cached UIViewControllers created by MCMainViewController
//
- (void)clearViewCache;


//--------------------------------------------------------------------------------
// Shows an error message above the main window, does not affect the history stack
//
- (void)setErrorTitle:(NSString*) title andDescription:(NSString*) description;


//--------------------------------------------------------------------------------
// Will process the given intent and place it as first responder
// Setting of the currentIntent needs to be wrapped in case we ever need to make changes again
//
- (void)processIntent:(MCIntent *)newCurrentIntent;


//--------------------------------------------------------------------------------
// DEPRECIATED, PLEASE USE : - (void)processIntent:(MCIntent *)newCurrentIntent;
//
//
- (void)setCurrentSection: (MCIntent *)currentIntent __deprecated;

@end
