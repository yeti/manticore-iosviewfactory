//
//  MCViewFactory.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCViewFactory.h"
#import "MCMainViewController.h"
#import <QuartzCore/QuartzCore.h>

#define AssertFileExists(path) NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot find the file: %@", path)
#define AssertNibExists(file_name_string) AssertFileExists([[NSBundle mainBundle] pathForResource:file_name_string ofType:@"nib"])

@interface MCViewFactoryEntry : NSObject {
}
@property NSString* nibName;
@property NSString* className;

@end

@implementation MCViewFactoryEntry
@synthesize nibName;
@synthesize className;

@end

@implementation MCViewFactory

static MCViewFactory* _sharedFactory = nil;

+(MCViewFactory*)sharedFactory
{
	@synchronized([MCViewFactory class])
	{
		if (!_sharedFactory)
			_sharedFactory = [[self alloc] init];
		return _sharedFactory;
	}
	return nil;
}

+(id)alloc
{
	@synchronized([MCViewFactory class])
	{
		NSAssert(_sharedFactory == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedFactory = [super alloc];
		return _sharedFactory;
	}
	return nil;
}

-(id)init{
  if (self = [super init]){
    viewControllers = [NSMutableDictionary dictionaryWithCapacity:20];
    [self registerView:VIEW_BUILTIN_MAIN andNibName:VIEW_BUILTIN_MAIN_NIB];
    [self registerView:VIEW_BUILTIN_ERROR andNibName:VIEW_BUILTIN_ERROR_NIB];
  }
  
  return self;
}

-(UIViewController*)createViewController:(NSString*)sectionOrViewName{
  MCViewFactoryEntry* entry = [viewControllers objectForKey:sectionOrViewName];
  Class class = NSClassFromString(sectionOrViewName);
  assert(class != nil);
  
  AssertNibExists(entry.nibName);
  UIViewController* vc = [[class alloc] initWithNibName:entry.nibName bundle:nil] ;
  
  NSLog(@"Created a view controller %@", vc);
  return vc;
}

-(void)registerView:(NSString*)sectionOrViewName{
  MCViewFactoryEntry* entry = [[MCViewFactoryEntry alloc] init];
  entry.nibName = sectionOrViewName;
  entry.className = sectionOrViewName;
  
  [viewControllers setObject:entry  forKey:sectionOrViewName];
}

-(void)registerView:(NSString*)sectionOrViewName andNibName:(NSString*)nibName {
  MCViewFactoryEntry* entry = [[MCViewFactoryEntry alloc] init];
  entry.nibName = nibName;
  entry.className = sectionOrViewName;
  
  [viewControllers setObject:entry  forKey:sectionOrViewName];
}


// this method offers custom animations that are not provided by UIView, mainly the
// slide left and right animations (no idea why Apple separated these animations)
+(BOOL)applyTransitionToView:(UIView*)view transition:(int)value { // not the best place for this code but it'll work for now
  NSString *transition = nil;
  NSString *subTransition = nil;
	if (value == ANIMATION_PUSH ) {
    transition = kCATransitionPush;
		subTransition = kCATransitionFromRight;
	} else if (value == ANIMATION_POP ) {
    transition = kCATransitionPush;
		subTransition = kCATransitionFromLeft;
  }
  else {
    return NO;
  }
  
  if(transition != nil) {
		// set up an animation for the transition between the views
		CATransition *animation = [CATransition animation];
		[animation setDuration:0.5];
		[animation setType:transition];
		[animation setSubtype:subTransition];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		[view.layer addAnimation:animation forKey:@"pageViewStack"];
	}
  
  return YES;
}


@end
