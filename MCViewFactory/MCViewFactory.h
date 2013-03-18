//
//  MCViewFactory.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VIEW_BUILTIN_ERROR @"MCErrorViewController"
#define VIEW_BUILTIN_MAIN @"MCMainViewController"

#define VIEW_BUILTIN_ERROR_NIB @"MCDefaultErrorViewController"
#define VIEW_BUILTIN_MAIN_NIB @"MCDefaultMainViewController"


@interface MCViewFactory : NSObject{
  NSMutableDictionary* viewControllers;
}

// singleton object
+(MCViewFactory*)sharedFactory;

// call this method on load
-(void)registerView:(NSString*)sectionOrViewName;

// call this method to instantiate a view
-(UIViewController*)createViewController:(NSString*)sectionOrViewName;

+(BOOL)applyTransitionToView:(UIView*)view transition:(int)value;

@end
