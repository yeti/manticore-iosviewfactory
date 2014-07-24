/*
  MCIntent.h
  Manticore iOSViewFactory

  Created by Richard Fung on 9/19/12.
  Copyright (c) 2013 Yeti LLC. All rights reserved.

 AppModelIntent is wired through AppModel and handled by MCMainViewController.
 
 ///////////////////////////////////////////////////////////////

 see the architecture design from Android:
 http://developer.android.com/reference/android/app/Activity.html

 ViewControllers are "activities" that receive bundles
 
 ///////////////////////////////////////////////////////////////
 

 How to use:

 1.  MCIntent* intent = [MCIntent intentWithSectionName:SECTION_?? viewName:VIEW_??]
     Create the intent object

 2. [[intent getSavedInstance] setObject:?? forKey:@"viewSpecificKey"]
     Assign any/all view-specific instructions. Read header files for definition.

 3. [[MCViewModel sharedModel] processIntent:intent];
     Load the section.
*/

#import <Foundation/Foundation.h>
#import "MCConstants.h"

@interface MCIntent : NSObject {
  NSString              *strSectionName;
  NSMutableDictionary   *dictSavedInstanceState;
}

// rarely any SECTION_ has no VIEW_
+(id) intentWithSectionName: (NSString*) name;

// only used by the undo operation
+(id) intentWithSectionName:(NSString*) name andSavedInstance:(NSMutableDictionary*) savedInstanceState;

// preferable animations are ANIMATION_NOTHING, ANIMATION_PUSH, ANIMATION_POP, UIViewAnimationOptionTransitionCrossDissolve
+(id) intentWithSectionName: (NSString*) name andAnimation:(UIViewAnimationOptions) animation;

// most commonly called SECTION_ and VIEW_ pairing
+(id) intentWithSectionName: (NSString*) sectionName andViewName: (NSString*) viewName;

// preferable animations are ANIMATION_NOTHING, ANIMATION_PUSH, ANIMATION_POP, UIViewAnimationOptionTransitionCrossDissolve
+(id) intentWithSectionName: (NSString*) sectionName andViewName:(NSString*)viewName andAnimation:(UIViewAnimationOptions)animation;

// intent for going to the last view, no animation
+(id) intentPreviousIntent;

// intent for going to the last view, any animation
+(id) intentPreviousIntentWithAnimation:(UIViewAnimationOptions)animation;

// intent for going to a specific view in the history stack
+(id) intentToLoadHistoricalIntentNumber: (NSNumber *) historyNum;

// getters
@property (nonatomic, retain, readonly) NSString* sectionName;
@property (nonatomic, retain, readonly) NSString* viewName;
@property (nonatomic, retain, readonly) NSMutableDictionary* savedInstanceState;
@property () UIViewAnimationOptions animationStyle;


@end
