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
#import "MCConstants.h"

@interface MCMainViewController : MCViewController {
  
  NSMutableDictionary *dictCacheView;
  MCErrorViewController* errorVC;
  MCSectionViewController* currentSectionVC;
  MCIntent* activeIntent;
  UIButton* screenOverlayButton;
  NSArray* screenOverlaySlideshow;
}


@end
