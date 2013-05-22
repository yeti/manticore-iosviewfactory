//
//  MCMainViewController.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/22/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//
// TODO: disable auto power off

#import <UIKit/UIKit.h>
#import "MCSectionViewController.h"
#import "MCErrorViewController.h"

#define MANTICORE_IOS5_SCREEN_SIZE 568
#define MANTICORE_IOS5_OVERLAY_SUFFIX @"_5"
#define MANTICORE_OVERLAY_ANIMATION_DURATION 0.2 // 200 ms

@interface MCMainViewController : MCViewController {
  
  NSMutableDictionary *dictCacheView;
  MCErrorViewController* errorVC;
  MCSectionViewController* currentSectionVC;
  MCIntent* activeIntent;
  UIButton* screenOverlayButton;
  NSArray* screenOverlaySlideshow;
}


@end
