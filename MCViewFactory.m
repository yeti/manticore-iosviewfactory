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


// ref. http://stackoverflow.com/questions/923706/checking-if-a-nib-or-xib-file-exists
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
  }
  
  return self;
}

-(UIViewController*)createViewController:(NSString*)sectionOrViewName{
  

  MCViewFactoryEntry* entry = [viewControllers objectForKey:sectionOrViewName];
  Class class = NSClassFromString(sectionOrViewName);
  NSAssert(class != nil, @"Class must exist");
  
  AssertNibExists(entry.nibName);
  UIViewController* vc = [[class alloc] initWithNibName:entry.nibName bundle:nil] ;
  
#ifdef DEBUG
  NSLog(@"Created a view controller %@", vc);
#endif
    
  return vc;
}

-(void)registerView:(NSString*)sectionOrViewName{
  MCViewFactoryEntry* entry = [[MCViewFactoryEntry alloc] init];
  entry.nibName = sectionOrViewName;
  entry.className = sectionOrViewName;
  
  [viewControllers setObject:entry  forKey:sectionOrViewName];
}

// DO WE NEED THIS ANYMORE ?????

//-(void)registerView:(NSString*)sectionOrViewName andNibName:(NSString*)nibName {
//  MCViewFactoryEntry* entry = [[MCViewFactoryEntry alloc] init];
//  entry.nibName = nibName;
//  entry.className = sectionOrViewName;
//  
//  [viewControllers setObject:entry  forKey:sectionOrViewName];
//}

// this method offers custom animations that are not provided by UIView, mainly the
// slide left and right animations (no idea why Apple separated these animations)
+(BOOL)applyTransitionFromView:(UIView*)oldView toView:(UIView*)newView transition:(int)value completion:(void (^)(void))completion  {
    
    // not the best place for this code but it'll work for now
    
    CGPoint finalPosition = oldView.center;
  
    CGPoint leftPosition = CGPointMake(-oldView.frame.size.width + finalPosition.x, finalPosition.y);
    CGPoint rightPosition = CGPointMake(finalPosition.x + oldView.frame.size.width, finalPosition.y);
    
    CGPoint closerLeftPosition = CGPointMake(finalPosition.x - 40, finalPosition.y);
    CGPoint closerRightPosition = CGPointMake(finalPosition.x + 40, finalPosition.y);

    
    CGPoint topPosition = CGPointMake(finalPosition.x, finalPosition.y + oldView.frame.size.height);
    CGPoint bottomPosition = CGPointMake(finalPosition.x, -oldView.frame.size.height + finalPosition.y);
  
    CGPoint closerTopPosition = CGPointMake(finalPosition.x, finalPosition.y - 40);
    CGPoint closerBottomPosition = CGPointMake(finalPosition.x, finalPosition.y + 40);

    if (value == ANIMATION_PUSH){
        newView.center = rightPosition;
        oldView.center = finalPosition;

        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
            oldView.center = closerLeftPosition;
            
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
    } else if (value == ANIMATION_PUSH_LEFT){
        newView.center = leftPosition;
        oldView.center = finalPosition;
        
        
        
        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
            oldView.center = closerRightPosition;
            
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
    } else if (value == ANIMATION_POP) {
        
        newView.center = closerLeftPosition;
        oldView.center = finalPosition;

        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
            newView.center = finalPosition;
            oldView.center = rightPosition;
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
        
    } else if (value == ANIMATION_POP_LEFT) {
        
        newView.center = closerRightPosition;
        oldView.center = finalPosition;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
            newView.center = finalPosition;
            oldView.center = leftPosition;
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
        
    } else if (value == ANIMATION_SLIDE_FROM_BOTTOM) {
      
      oldView.center = finalPosition;
      newView.center = topPosition;
        
        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
          oldView.center = closerTopPosition;
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
        
    } else if (value == ANIMATION_SLIDE_FROM_TOP) {
        newView.center = bottomPosition;
      oldView.center = finalPosition;

        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
          oldView.center = closerBottomPosition;

        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
      
    } else if (value == kAnimationPopToBottom) {
      
      newView.center = closerTopPosition;
      oldView.center = finalPosition;

      [UIView animateWithDuration:0.5 animations:^{
        oldView.center = topPosition;
        newView.center = finalPosition;
      } completion:^(BOOL finished) {
        completion();
        oldView.center = finalPosition;
      }];
      
      return YES;
    } else if (value == kAnimationPopToTop) {

      
      return YES;
    } else {
        return NO;
    }
}


@end
