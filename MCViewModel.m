//
//  MCAppModel.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 3/15/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCViewModel.h"

@implementation MCViewModel


@synthesize errorDict;
@synthesize currentIntent;
@synthesize historyStack;
@synthesize screenOverlay;
@synthesize stackSize;


#pragma mark - Initialization & Singleton

- (id) init {
  if (self = [super init]){
    stackSize = 0;
    [self clearHistoryStack];
  }
  
  return self;
}


// -------------------------------------------------------------------------------
// Function to get the singleton
//
+(MCViewModel *)sharedModel
{
    static MCViewModel* sharedModel = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedModel = [[MCViewModel alloc] init];
    });
    return sharedModel;
}


#pragma mark -

//--------------------------------------------------------------------------------
// Clear the history of intents
//
- (void) clearHistoryStack{
    historyStack = [NSMutableArray arrayWithCapacity:stackSize];
}


//--------------------------------------------------------------------------------
// Clear the cached UIViewControllers created by MCMainViewController
//
- (void) clearViewCache {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MCMainViewController_flushViewCache" object:self];
}


#pragma mark -

//--------------------------------------------------------------------------------
// Shows an error message above the main window, does not affect the history stack
//
-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description
{
  if (title == nil)
    title = @"";
  
  if (description == nil)
    description = @"";
  
  [self setErrorDict: [NSDictionary dictionaryWithObjects:@[title, description] forKeys:@[@"title", @"description"]]];
}


#pragma mark -

//--------------------------------------------------------------------------------
// Will process the given intent and place it as first responder
//
-(void) processIntent:(MCIntent *)newCurrentIntent {
  [self setCurrentIntent: newCurrentIntent];
}

@end
