//
//  MCViewFactory.m
//  Manticore iOSViewFactory
//
//  Created by Philippe Bertin on August 1, 2014
//  Copyright (c) 2014 Yeti LLC. All rights reserved.
//

#import "MCViewManager.h"
#import "MCMainViewController.h"
#import <QuartzCore/QuartzCore.h>


// ref. http://stackoverflow.com/questions/923706/checking-if-a-nib-or-xib-file-exists
#define AssertFileExists(path) NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot find the file: %@", path)
#define AssertNibExists(file_name_string) AssertFileExists([[NSBundle mainBundle] pathForResource:file_name_string ofType:@"nib"])



#pragma mark
#pragma mark - MCViewManager class

@interface MCViewManager ()

// Error dictionary observed by MCMainViewController
@property(atomic, strong) NSDictionary *errorDict;

// Pointer to the current Activity, observed by MCMainViewController
@property(atomic, strong) MCActivity     *currentActivity;

@end


@implementation MCViewManager


@synthesize historyStack;
@synthesize screenOverlay;
@synthesize screenOverlays;


#pragma mark - Initialization

-(id)init{
    if (self = [super init]){
        _stackSize = 0;
        [self clearHistoryStack];
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


#pragma mark - View-Controllers related


-(UIViewController*)createViewController:(NSString*)sectionOrViewName
{
    // Get the class from string
    Class class = NSClassFromString(sectionOrViewName);
    
    // Assert the class exists and the nib file exists
    NSAssert(class != nil, @"You tried to instanciate a Class that does not exists : %@. Class must exist.", sectionOrViewName);
    
    // Assert the nib file exists
    AssertNibExists(sectionOrViewName);
    
    // Create the viewController
    UIViewController* vc = [[class alloc] initWithNibName:sectionOrViewName bundle:nil] ;
  
#ifdef DEBUG
    NSLog(@"Created a view controller %@", [vc description]);
#endif
    
  return vc;
}


-(void) processActivity:(MCActivity *)newCurrentActivity
{
    [self setCurrentActivity: newCurrentActivity];
}



#pragma mark -


- (void) clearHistoryStack
{
    historyStack = [NSMutableArray arrayWithCapacity:_stackSize];
}


- (void) clearViewCache
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCMainViewController_flushViewCache" object:self];
}


#pragma mark -

-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description
{
    if (title == nil)
        title = @"";
    
    if (description == nil)
        description = @"";
    
    [self setErrorDict: [NSDictionary dictionaryWithObjects:@[title, description] forKeys:@[@"title", @"description"]]];
}

# pragma mark - Setters / Getters

-(void)setStackSize:(int)stackSize
{
    // Verify stackSize if >= 0
    NSAssert(stackSize >= 0, @"Stack size can not be less than 0, you tried to set it at %i", stackSize);
    _stackSize = stackSize;
}


@end
