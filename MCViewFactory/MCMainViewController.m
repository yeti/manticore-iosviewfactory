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
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushViewCache:) name:@"MCMainViewController_flushViewCache" object:[MCViewModel sharedModel]]; // last parameter filters the response

    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{

  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  
  dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
}

// Selector that specifies the message the receiver sends notificationObserver to notify it of the notification posting. The method specified by notificationSelector must have one and only one argument (an instance of NSNotification).
-(void)flushViewCache:(id)sender{
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

-(MCViewController*) loadOrCreateViewController:(NSString*)sectionOrViewName{
  // create global view cache if it doesn't already exist
  if (!dictCacheView){
    dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
  }
  
  // test for existence
  MCViewController* vc = [dictCacheView objectForKey:sectionOrViewName];
  if (vc == nil){
    // create the view controller
    vc = (MCViewController*) [[MCViewFactory sharedFactory] createViewController:sectionOrViewName];
    NSAssert(vc != nil, @"VC should exist");
    [dictCacheView setObject:vc forKey:sectionOrViewName];
  }
  
  return vc;
}

-(void)pushToHistoryStack:(MCIntent*)intent{
  if ([MCViewModel sharedModel].stackSize == STACK_SIZE_DISABLED){
    // don't save anything to the stack
    return;
  }else if ([MCViewModel sharedModel].stackSize != STACK_SIZE_UNLIMITED){
    // bound the size 
    NSAssert([MCViewModel sharedModel].stackSize > 0, @"valid stack size is defined");
    
    if ([MCViewModel sharedModel].historyStack.count >= [MCViewModel sharedModel].stackSize  && [MCViewModel sharedModel].historyStack > 0){
      [[MCViewModel sharedModel].historyStack removeObjectAtIndex:0]; // remove the first object to keep the stack size bounded
    }
  }
  
  // add the new object on the stack
  [[[MCViewModel sharedModel] historyStack] addObject:intent];
}

-(MCIntent*)popHistoryStack{
  NSAssert([MCViewModel sharedModel].historyStack.count > 0, @"something on the stack");
  
  if ([MCViewModel sharedModel].historyStack.count > 0){
    [[MCViewModel sharedModel].historyStack removeLastObject]; // this is the shown view, we don't want to stay on this view so discard it
    MCIntent* retIntent = [[MCViewModel sharedModel].historyStack lastObject]; // this is the previous view, we keep a ref to this
    return retIntent;
  }
  
  return nil; // nothing on the history stack
}

-(MCIntent*)loadIntentAndHandleHistoryStack:(MCIntent*)intent{
  if ([[intent sectionName] isEqualToString:SECTION_LAST]){
    // but don't retain the SECTION or VIEW
    NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[intent savedInstanceState]];
    [savedState removeObjectForKey:@"viewName"]; // unusual design decision, sectionName is not saved in the savedState object
    
    // when  copying state values from the given intent, e.g., animation transition, to the old bundle
    MCIntent* previousIntent = [self popHistoryStack];
    NSAssert(previousIntent != nil, @"Cannot pop an empty history stack. You can check for an empty history stack by inspecting [MCViewModel sharedModel].historyStack.count > 1");
    if (previousIntent == nil){
      // default behaviour is to stop changing intents, the current intent is set to an improper state
      return nil;
    }
    
    // replace the intent on the history stack
    [[previousIntent savedInstanceState] setValuesForKeysWithDictionary:savedState];
    return previousIntent;
  }else{
    // build the history stack
    [self pushToHistoryStack:intent];
  }

  return intent;
}

-(void)goToSection:(MCIntent*)intent{
  // handle the history stack
  intent = [self loadIntentAndHandleHistoryStack:intent];
  if (!intent)
    return;
  
  // load the appropriate views from cache

  MCSectionViewController* sectionVC =  (MCSectionViewController*)  [self loadOrCreateViewController:[intent sectionName]];
  NSAssert([sectionVC isKindOfClass:[MCSectionViewController class]], @"sections should be subclasses of MCSectionViewController");
  
  MCViewController* vc = nil;
  if ([intent viewName]){
    vc = (MCViewController*) [self loadOrCreateViewController:[intent viewName]];
    NSAssert([vc isKindOfClass:[MCViewController class]], @"views should be subclasses of MCViewController");
  
    // edge case: everything we are transitioning to is the same as the previous, need to create a new view
    if (sectionVC == currentSectionVC && vc == currentSectionVC.currentViewVC){
      sectionVC = (MCSectionViewController*) [[MCViewFactory sharedFactory] createViewController:[intent sectionName]];
      [dictCacheView setObject:sectionVC forKey:[intent sectionName]];
      
      vc = (MCViewController*) [[MCViewFactory sharedFactory] createViewController:[intent viewName]];
      [dictCacheView setObject:vc forKey:[intent viewName]];
    }
  }else{
    // edge case: transitioning from itself to itself, need to create a new view
    if (sectionVC == currentSectionVC){
      sectionVC = (MCSectionViewController*) [[MCViewFactory sharedFactory] createViewController:[intent sectionName]];
      [dictCacheView setObject:sectionVC forKey:[intent sectionName]];
    }
  }

  // save changes to the previous intent
  // automatically propagates onPause to its child view
  if (currentSectionVC){
    [currentSectionVC onPause:activeIntent];
  }

  // switch the views
  [self loadNewSection:sectionVC andView:vc withIntent:intent];
  
  // resume on the section will also resume the view
  activeIntent = intent;
  [sectionVC onResume:intent];
}

-(void)loadNewSection:(MCSectionViewController*)sectionVC andView:(MCViewController*)vc withIntent:(MCIntent*)intent{
  int transitionStyle = [intent animationStyle];
  
  if (currentSectionVC != sectionVC){ // replace the section VC
    
    [self addChildViewController:sectionVC];
    [self.view addSubview:sectionVC.view];
    

    MCSectionViewController* oldSectionVC = currentSectionVC;

    // opResult becomes true when an animation is applied, then we don't need to call our other animation code
//    BOOL opResult = [MCViewFactory applyTransitionToView:self.view transition:transitionStyle];
    BOOL opResult = [MCViewFactory applyTransitionFromView:currentSectionVC.view toView:sectionVC.view transition:transitionStyle completion:^{
      [oldSectionVC.view removeFromSuperview];
      [oldSectionVC removeFromParentViewController];
    }];
    
    
    if (!opResult){ // if animation was not applied
      [oldSectionVC.currentViewVC resignFirstResponder];
      [oldSectionVC resignFirstResponder];

      [UIView transitionFromView:currentSectionVC.view toView:sectionVC.view duration:0.25 options:[intent animationStyle] completion:^(BOOL finished) {
        // these 4 lines are the same as below
        [oldSectionVC.view removeFromSuperview];
        [oldSectionVC removeFromParentViewController];
      }];
    }
    
    NSAssert(self.view.subviews.count < 5, @"clearing the view stack");
    
    currentSectionVC = sectionVC;
    
    // reset the animation style, don't animate the view if the section has already been animated
    transitionStyle = UIViewAnimationOptionTransitionNone;
  }
  
  
  if (vc){ // load the view inside the section
    MCViewController* currentViewVC = sectionVC.currentViewVC;
    
    // if the view controller is the same as before, don't load it again
    if (currentViewVC != vc){
      
      [sectionVC addChildViewController:vc];
      [sectionVC.innerView addSubview:vc.view];
      
      // opResult becomes true when an animation is applied, then we don't need to call our other animation code
//      BOOL opResult = [MCViewFactory applyTransitionToView:sectionVC.innerView transition:[intent animationStyle]];
      BOOL opResult = [MCViewFactory applyTransitionFromView:currentViewVC.view toView:vc.view transition:transitionStyle completion:^{
        [currentViewVC.view removeFromSuperview];
        [currentViewVC removeFromParentViewController];
      }];
      [currentViewVC resignFirstResponder];
      
      if (currentViewVC.view != vc.view && !opResult){
        [UIView transitionFromView:currentViewVC.view toView:vc.view duration:0.250 options:[intent animationStyle] completion:^(BOOL finished) {
          [currentViewVC.view removeFromSuperview];
          [currentViewVC removeFromParentViewController];
        }];
      }
     
      NSAssert(sectionVC.innerView.subviews.count < 5, @"clearing the view stack");
    }
    currentSectionVC.currentViewVC = vc;    
  }
}

-(void)clearView:(UIViewController*) view {
	for (UIViewController *vc in view.childViewControllers) {
    [vc.view resignFirstResponder]; // close the keyboard
		[vc.view removeFromSuperview];
	}
	
  [view.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
  
}

@end
