//
//  MCViewController.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 9/19/12.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppModelIntent.h"

@interface MCViewController : UIViewController


// When overriding these methods, the superclass's onResume and onPause must be called.
-(void)onResume:(AppModelIntent*)intent;
-(void)onPause:(AppModelIntent*)intent; // TODO: onPause is implmented for Sections; not implemented for Views

@end
