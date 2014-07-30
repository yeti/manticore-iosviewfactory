//
//  MCViewFactory.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCConstants.h"

@interface MCViewManager : NSObject {
    NSMutableDictionary* viewControllers;
}

// -------------------------------------------------------------------------------------------
// Get the singleton instance.
//
+(MCViewManager*)sharedManager;



// -------------------------------------------------------------------------------------------
// Low-level function that creates and return a ViewController.
// Does not provide caching and Manticore events (onCreate, ...)
//
// Input : name of a sectionViewController or a viewController
//
-(UIViewController*)createViewController:(NSString*)sectionOrViewName;



// -------------------------------------------------------------------------------------------
// Each view needs to be registered in order to be managed by Manticore.
// This method should be called one time for each viewController.
//
-(void)registerView:(NSString*)sectionOrViewName;



// -------------------------------------------------------------------------------------------
// this method offers custom animations that are not provided by UIView, mainly the
// slide left and right animations (no idea why Apple separated these animations)
//
//
+(BOOL)applyTransitionFromView:(UIView*)oldView toView:(UIView*)newView transition:(int)value completion:(void (^)(void))completion;


@end
