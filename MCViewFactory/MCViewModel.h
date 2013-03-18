//
//  MCAppModel.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 3/15/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppModelIntent.h"

@interface MCViewModel : NSObject

// view
@property(nonatomic,retain) NSDictionary* errorDict;
@property(nonatomic, retain) AppModelIntent* currentSection;

+(MCViewModel*)sharedModel;

-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description;

@end
