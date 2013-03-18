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

-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description
{
  [self setErrorDict: [NSDictionary dictionaryWithObjects:@[title, description] forKeys:@[@"title", @"description"]]];
}


@end
