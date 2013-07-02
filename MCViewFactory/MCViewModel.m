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
@synthesize currentSection;
@synthesize historyStack;
@synthesize screenOverlay;
@synthesize stackSize;

MCViewModel* _sharedModel;

+(MCViewModel*)sharedModel
{
	@synchronized([MCViewModel class])
	{
		if (!_sharedModel)
			_sharedModel = [[self alloc] init];
		return _sharedModel;
	}
	return nil;
}

-(id)init{
  if (self = [super init]){
    stackSize = 0;
    [self clearHistoryStack];
  }
  
  return self;
}

-(void)clearHistoryStack{
    historyStack = [NSMutableArray arrayWithCapacity:stackSize];
}

-(void)clearViewCache{
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MCMainViewController_flushViewCache" object:self];
}

-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description
{
  if (title == nil)
    title = @"";
  
  if (description == nil)
    description = @"";
  
  [self setErrorDict: [NSDictionary dictionaryWithObjects:@[title, description] forKeys:@[@"title", @"description"]]];
}

@end
