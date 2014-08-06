//
//  MCViewManager.h
//  Manticore iOS-ViewManager
//
//  Created by Philippe Bertin on August 1, 2014
//  Copyright (c) 2014 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCConstants.h"
#import "MCIntent.h"



/*
//  MCViewManager is responsible for managing and processing the
//      application's view-controllers. Whenever possible, you 
//      should use intents. If you can not for some reason,
//      a method is provided to you for easy VC creation.
//
//  You should use this class to manage your view-controllers :
//
//      - Process an intent pointing to your desired VC
//      - Clear the VCs cache
//      - Clear your view-controller's history stack
//      - Show error-messages
//      - Create view-controllers that do not need to be managed by
//          manticore. Example
//
//
*/
@interface MCViewManager : NSObject


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
@property(nonatomic) int stackSize;



// ------------------------------------------------------------------
// Get the singleton instance.
//
+(MCViewManager*)sharedManager;


// ------------------------------------------------------------------
// Low-level function that creates and return a ViewController.
// Does not provide caching and Manticore events (onCreate, ...)
//
// Input : name of a View-Controller owning a nib file.
//
-(UIViewController*)createViewController:(NSString*)sectionOrViewName;


//--------------------------------------------------------------------------------
// Will process the given intent and place it as first responder
// Setting of the currentIntent needs to be wrapped in case we ever need to make changes again
//
- (void)processIntent:(MCIntent *)newCurrentIntent;


//--------------------------------------------------------------------------------
// Clear the history of intents
//
- (void)clearHistoryStack;


//--------------------------------------------------------------------------------
// Clear the cached UIViewControllers created by MCMainViewController
//
- (void)clearViewCache;


//--------------------------------------------------------------------------------
// Using this function will shows an error message
//      above the main window given the title and description.
// It will not affect the history stack.
//
- (void)setErrorTitle:(NSString*) title andDescription:(NSString*) description;


@end
