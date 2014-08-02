//
//  MCMainViewController.h
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/22/13.
//  Reworked, refactored and commented by Philippe Bertin on August 1, 2014
//  Copyright (c) 2014 Yeti LLC. All rights reserved.
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
