//
//  MCViewFactory.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCConstants.h"

@interface MCViewManager : NSObject 

// ------------------------------------------------------------------
// Get the singleton instance.
//
+(MCViewManager*)sharedManager;



// -------------------------------------------------------------------
// Each view needs to be registered in order to be managed by Manticore.
// This method should be called one time for each viewController.
//
-(void)registerView:(NSString*)sectionOrViewName;



// ------------------------------------------------------------------
// Low-level function that creates and return a ViewController.
// Does not provide caching and Manticore events (onCreate, ...)
//
// Input : name of a sectionViewController or a viewController that
//     was previously registered
//
-(UIViewController*)createViewController:(NSString*)sectionOrViewName;


@end
