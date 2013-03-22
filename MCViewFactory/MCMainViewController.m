//
//  MCMainViewController.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/22/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCViewController.h"
#import "MCViewModel.h"
#import "MCErrorViewController.h"
#import "MCMainViewController.h"
#import "MCSectionViewController.h"
#import "MCViewFactory.h"

@interface MCMainViewController ()

@end

@implementation MCMainViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
      // register to listeners on model changes
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"currentSection" options: NSKeyValueObservingOptionNew context: nil];
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"errorDict" options: NSKeyValueObservingOptionNew context: nil];

    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{

  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.

  // the responsbility of this code is to load the first view that is shown

   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
  
  dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
}


// callback from the observer listener pattern
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"currentSection"]) {
    [self goToSection:[MCViewModel sharedModel].currentSection];
  } 
  else if ([keyPath isEqual:@"errorDict"]) {
  //NSDictionary *errorDict = [change objectForKey:NSKeyValueChangeNewKey];
  //[errorDict objectForKey: @"name"];
    
    if (!errorVC)
      errorVC = (MCErrorViewController*) [[MCViewFactory sharedFactory] createViewController:VIEW_BUILTIN_ERROR];
    
    // remove from the previous
    [errorVC.view removeFromSuperview];
    [errorVC removeFromParentViewController];
    
    // set up
    [errorVC loadLatestErrorMessage];

    // add to the current
    [errorVC.view setFrame:[self.view bounds]];
    [self.view addSubview: errorVC.view];
    
    [currentSectionVC.currentViewVC.view resignFirstResponder];
    [currentSectionVC.view resignFirstResponder];

    
    [errorVC becomeFirstResponder]; // make the error dialog the first responder
    
  
  }
  
}

-(void)goToSection:(MCIntent*)intent{
  
  if (!dictCacheView)
  {
    dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
  }
  
  MCSectionViewController* sectionVC = [dictCacheView objectForKey:[intent sectionName]];
  if (sectionVC == nil){
    sectionVC = (MCSectionViewController*) [[MCViewFactory sharedFactory] createViewController:[intent sectionName]];
    NSAssert(sectionVC != nil, @"Section VC should exist");
    [dictCacheView setObject:sectionVC forKey:[intent sectionName]];
  }
  
  MCViewController* vc=nil;
  if ([intent viewName]){
    vc = [dictCacheView objectForKey:[intent viewName]];
    if (vc == nil){
      vc = (MCViewController*) [[MCViewFactory sharedFactory] createViewController:[intent viewName]];
      NSAssert(vc != nil, @"VC should exist");
      [dictCacheView setObject:vc forKey:[intent viewName]];

    }

  }
    

  if (currentSectionVC){
    [currentSectionVC onPause:intent];
  }

  if (currentSectionVC != sectionVC){ // replace the section VC
    
    [self addChildViewController:sectionVC];
    [self.view addSubview:sectionVC.view];

    // opResult becomes true when an animation is applied, then we don't need to call our other animation code
    BOOL opResult = [MCViewFactory applyTransitionToView:self.view transition:[intent animationStyle]];

    MCSectionViewController* oldSectionVC = currentSectionVC;
    
    if (!opResult){
      [UIView transitionFromView:currentSectionVC.view toView:sectionVC.view duration:0.25 options:[intent animationStyle] completion:^(BOOL finished) {
        [oldSectionVC.currentViewVC resignFirstResponder];
        [oldSectionVC resignFirstResponder];
        [oldSectionVC.view removeFromSuperview];
        [oldSectionVC removeFromParentViewController];
        
      }];
      

    }else{
      [oldSectionVC.currentViewVC resignFirstResponder];
      [oldSectionVC resignFirstResponder];
      [oldSectionVC.view removeFromSuperview];
      [oldSectionVC removeFromParentViewController];
    }
    
    currentSectionVC = sectionVC;
    
    // reset the animation style
    [intent setAnimationStyle:UIViewAnimationOptionTransitionNone];
  }
  
 
  if (vc){
    
    MCViewController* currentViewVC = sectionVC.currentViewVC;
    
    
    if (currentViewVC != vc){

      [sectionVC addChildViewController:vc];
      [sectionVC.innerView addSubview:vc.view];

      // opResult becomes true when an animation is applied, then we don't need to call our other animation code
      BOOL opResult = [MCViewFactory applyTransitionToView:sectionVC.innerView transition:[intent animationStyle]];

      if (currentViewVC.view != vc.view && !opResult){
        [UIView transitionFromView:currentViewVC.view toView:vc.view duration:0.250 options:[intent animationStyle] completion:^(BOOL finished) {
          [currentViewVC resignFirstResponder];
          [currentViewVC.view removeFromSuperview];
          [currentViewVC removeFromParentViewController];
        }];
      }else{
        [currentViewVC resignFirstResponder];
        [currentViewVC.view removeFromSuperview];
        [currentViewVC removeFromParentViewController];
      }
      
    }
    currentSectionVC.currentViewVC = vc;

  }
  
  [sectionVC onResume:intent];
  
}


-(void)clearView:(UIViewController*) view {
	for (UIViewController *vc in view.childViewControllers) {
    [vc.view resignFirstResponder]; // close the keyboard
		[vc.view removeFromSuperview];
	}
	
  [view.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
  
}

@end
