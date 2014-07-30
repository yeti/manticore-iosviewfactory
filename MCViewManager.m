//
//  MCViewFactory.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/31/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCViewManager.h"
#import "MCMainViewController.h"
#import <QuartzCore/QuartzCore.h>


// ref. http://stackoverflow.com/questions/923706/checking-if-a-nib-or-xib-file-exists
#define AssertFileExists(path) NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot find the file: %@", path)
#define AssertNibExists(file_name_string) AssertFileExists([[NSBundle mainBundle] pathForResource:file_name_string ofType:@"nib"])



#pragma mark
#pragma mark - MCViewManagerEntry class

// -------------------------------------------------------------------------------------------
// Object representing a registered view : MCViewManagerEntry
//
@interface MCViewManagerEntry : NSObject
@property NSString* nibName;
@property NSString* className;
@end

@implementation MCViewManagerEntry
@synthesize nibName;
@synthesize className;
@end


#pragma mark
#pragma mark - MCViewManager class

@interface MCViewManager ()

// Containes 
//@property (strong, nonatomic) NSMutableDictionary* viewControllers;

@end


@implementation MCViewManager

#pragma mark - Initialization

-(id)init{
    if (self = [super init]){
        viewControllers = [NSMutableDictionary dictionaryWithCapacity:20];
    }
    return self;
}


// --------------------------------------------------------------------------------------------
// Function to get the singleton
//
+(MCViewManager *)sharedManager
{
    static MCViewManager* sharedManager = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[MCViewManager alloc] init];
    });
    return sharedManager;
}


#pragma mark - Low-level function

// -------------------------------------------------------------------------------------------
// Low-level function that creates and return a ViewController.
// Does not provide caching and Manticore events (onCreate, ...)
//
// Input : name of a sectionViewController or a viewController
//
-(UIViewController*)createViewController:(NSString*)sectionOrViewName{
  
  MCViewManagerEntry* entry = [viewControllers objectForKey:sectionOrViewName];
  Class class = NSClassFromString(sectionOrViewName);
  NSAssert(class != nil, @"Class must exist");
  
  AssertNibExists(entry.nibName);
  UIViewController* vc = [[class alloc] initWithNibName:entry.nibName bundle:nil] ;
  
#ifdef DEBUG
  NSLog(@"Created a view controller %@", vc);
#endif
    
  return vc;
}


#pragma mark - View registration

// -------------------------------------------------------------------------------------------
// Each view needs to be registered in order to be managed by Manticore.
// This method should be called one time for each viewController.
//
// Shouldn't it be registerViewController ????????
// Make a test and not register if already present in array ?????????
//
-(void)registerView:(NSString*)sectionOrViewName{
  MCViewManagerEntry* entry = [[MCViewManagerEntry alloc] init];
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




#pragma mark - Apply view transition

// -------------------------------------------------------------------------------------------
// this method offers custom animations that are not provided by UIView, mainly the
// slide left and right animations (no idea why Apple separated these animations)
//
+(BOOL)applyTransitionFromView:(UIView*)oldView toView:(UIView*)newView transition:(int)value completion:(void (^)(void))completion  {
    
    // not the best place for this code but it'll work for now
    
    CGPoint finalPosition = oldView.center;
    CGPoint leftPosition = CGPointMake(-oldView.frame.size.width + finalPosition.x, finalPosition.y);
    CGPoint rightPosition = CGPointMake(finalPosition.x + oldView.frame.size.width, finalPosition.y);
    
    CGPoint closerLeftPosition = CGPointMake(finalPosition.x - 40, finalPosition.y);
    CGPoint closerRightPosition = CGPointMake(finalPosition.x + 40, finalPosition.y);

    
    CGPoint topPosition = CGPointMake(finalPosition.x, finalPosition.y + oldView.frame.size.height);
    CGPoint bottomPosition = CGPointMake(finalPosition.x, -oldView.frame.size.height + finalPosition.y);

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
        
        newView.center = topPosition;
        
        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
        
    } else if (value == ANIMATION_SLIDE_FROM_TOP) {
        newView.center = bottomPosition;
        
        [UIView animateWithDuration:0.5 animations:^{
            newView.center = finalPosition;
        } completion:^(BOOL finished) {
            completion();
            oldView.center = finalPosition;
        }];
        return YES;
    } else {
        return NO;
    }
}


@end
