//
//  MCViewFactory.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCConstants.h"

@interface MCViewFactory : NSObject{
  NSMutableDictionary* viewControllers;
}

// singleton object
+(MCViewFactory*)sharedFactory;

// call this method on load
-(void)registerView:(NSString*)sectionOrViewName;

// call this method to instantiate a view
-(UIViewController*)createViewController:(NSString*)sectionOrViewName;

+(BOOL)applyTransitionFromView:(UIView*)oldView toView:(UIView*)newView transition:(int)value completion:(void (^)(void))completion;

@end
