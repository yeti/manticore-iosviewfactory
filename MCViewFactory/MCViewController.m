//
//  MCViewController.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 9/19/12.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCViewController.h"

@implementation MCViewController

@synthesize debugTag;

-(void)onCreate{
  
}

-(void)onResume:(MCIntent*)intent
{
  self.debugTag = YES;
}

-(void)onPause:(MCIntent*)intent
{
  self.debugTag = YES;
}

@end
