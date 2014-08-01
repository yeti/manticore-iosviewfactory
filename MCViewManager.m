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

// Contains all the registered
@property (strong, nonatomic) NSMutableDictionary* viewControllers;

@end


@implementation MCViewManager

#pragma mark - Initialization

-(id)init{
    if (self = [super init]){
        _viewControllers = [NSMutableDictionary dictionaryWithCapacity:20];
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
  
  MCViewManagerEntry* entry = [_viewControllers objectForKey:sectionOrViewName];
  Class class = NSClassFromString(sectionOrViewName);
  NSAssert(class != nil, @"You tried to instanciate a Class that does not exists : %@. Class must exist.", sectionOrViewName);
  
    // Replace when removing entry class
  AssertNibExists(entry.nibName);
  UIViewController* vc = [[class alloc] initWithNibName:entry.nibName bundle:nil] ;
  
#ifdef DEBUG
  NSLog(@"Created a view controller %@", [vc description]);
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
  
  [_viewControllers setObject:entry  forKey:sectionOrViewName];
}


@end
