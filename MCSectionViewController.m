//
//  MCSectionViewController.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 2/7/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCSectionViewController.h"
#import "MCViewFactory.h"

@interface MCSectionViewController ()

@end

@implementation MCSectionViewController

@synthesize innerView;
@synthesize currentViewVC;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
  
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)onResume:(MCIntent *)intent{
  [super onResume:intent];
  
  if (currentViewVC) {
    [currentViewVC onResume:intent];
  }
  
  
}

-(void)onPause:(MCIntent *)intent{
  if (currentViewVC){
    [currentViewVC onPause:intent];
  }
  [super onPause:intent];

}

@end
