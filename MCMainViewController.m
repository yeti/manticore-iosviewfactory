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



// this function taken from http://stackoverflow.com/questions/10330679/how-to-dispatch-on-main-queue-synchronously-without-a-deadlock
void manticore_runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
  if ([NSThread isMainThread])
  {
    block();
  }
  else
  {
    dispatch_sync(dispatch_get_main_queue(), block);
  }
}

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
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"screenOverlay" options: NSKeyValueObservingOptionNew context: nil];
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"screenOverlays" options: NSKeyValueObservingOptionNew context: nil];
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
	if ([keyPath isEqualToString:@"currentSection"]) {
      manticore_runOnMainQueueWithoutDeadlocking(^{
        [self goToSection:[MCViewModel sharedModel].currentSection];
      });
    
  } 
  else if ([keyPath isEqualToString:@"errorDict"]) {
  //NSDictionary *errorDict = [change objectForKey:NSKeyValueChangeNewKey];
  //[errorDict objectForKey: @"name"];
      manticore_runOnMainQueueWithoutDeadlocking(^{
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
      });
  }else if ([keyPath isEqualToString:@"screenOverlay"]){
    manticore_runOnMainQueueWithoutDeadlocking(^{
      [self overlaySlideshow:@[[MCViewModel sharedModel].screenOverlay]];
    });
  }
  else if ([keyPath isEqualToString:@"screenOverlays"]){
    manticore_runOnMainQueueWithoutDeadlocking(^{
      [self overlaySlideshow:[MCViewModel sharedModel].screenOverlays];
    });
  }else{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
  
}

-(void)overlaySlideshow:(NSArray*)overlays{
  screenOverlaySlideshow = overlays;
  
  if (!overlays || overlays.count == 0){
    if (screenOverlayButton){
      // fade out the overlay in 200 ms
      screenOverlayButton.alpha = 1.0;
      [UIView animateWithDuration:MANTICORE_OVERLAY_ANIMATION_DURATION animations:^{
        screenOverlayButton.alpha = 0.0;
      } completion:^(BOOL finished) {
        [screenOverlayButton resignFirstResponder];
        [screenOverlayButton removeFromSuperview];
        screenOverlayButton = nil;
      }];
    }
    return;
  }
  
  // load the overlay 
  if (!screenOverlayButton){
    // set up the geometry of the new screen overlay
    CGRect rect = [self.view bounds];
    screenOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    screenOverlayButton.frame = rect;
    screenOverlayButton.contentMode = UIViewContentModeScaleToFill;
  }
  
  // this code will load 2 images on iPhone 5, one for the small screen and another image for the large screen
  
  // automatically remove the .png/.PNG extension
  NSString* overlayName = [overlays objectAtIndex:0];
  if ([[overlayName pathExtension] compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame){
    overlayName = [overlayName stringByDeletingPathExtension];
  }
  // load the image
  UIImage* imgOverlay = [UIImage imageNamed:overlayName];
  
  // check screen dimensions
  CGRect appFrame = [[UIScreen mainScreen] bounds];
  if (appFrame.size.height >= MANTICORE_IOS5_SCREEN_SIZE) // add in the _5 to the filename, shouldn't append .png
  {
    // test for an iPhone 5 overlay. If available, use that overlay instead.
    overlayName = [NSString stringWithFormat:@"%@%@", overlayName, MANTICORE_IOS5_OVERLAY_SUFFIX];
    if ([UIImage imageNamed:overlayName]){
      imgOverlay = [UIImage imageNamed:overlayName];
    }
  }
  
  // show the new overlay
  if (imgOverlay){
    [screenOverlayButton setImage:imgOverlay forState:UIControlStateNormal];
    [screenOverlayButton addTarget:self action:@selector(overlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    if (![self.view.subviews containsObject:screenOverlayButton]){
      screenOverlayButton.alpha = 0.0;
      [self.view addSubview:screenOverlayButton ];
      [UIView animateWithDuration:MANTICORE_OVERLAY_ANIMATION_DURATION animations:^{
        screenOverlayButton.alpha = 1.0;
      }];
    }
    [self.view bringSubviewToFront:screenOverlayButton];
    [screenOverlayButton becomeFirstResponder];
  }else{
#ifdef DEBUG
    NSAssert(false, @"Screen overlay not found: %@", [MCViewModel sharedModel].screenOverlay);
#endif
  }

}

- (void)overlayButtonPressed:(id)sender{
  NSMutableArray* newArray = [NSMutableArray arrayWithArray:screenOverlaySlideshow];
  if (newArray.count > 0)
    [newArray removeObjectAtIndex:0];
  screenOverlaySlideshow = newArray;
  [self overlaySlideshow:newArray];
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
    
    [vc onCreate];
    [dictCacheView setObject:vc forKey:sectionOrViewName];
  }
  
  return vc;
}

-(MCViewController*) forceLoadViewController:(NSString*)sectionOrViewName{
  // create global view cache if it doesn't already exist
  if (!dictCacheView){
    dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
  }

  // create the view controller
  MCViewController* vc = (MCViewController*) [[MCViewFactory sharedFactory] createViewController:sectionOrViewName];
  NSAssert(vc != nil, @"VC should exist");
  [vc onCreate];
  [dictCacheView setObject:vc forKey:sectionOrViewName];
  return vc;
}

-(void)pushToHistoryStack:(MCIntent*)intent{
  if ([MCViewModel sharedModel].stackSize == STACK_SIZE_DISABLED){
    // don't save anything to the stack
    return;
  }else if ([MCViewModel sharedModel].stackSize != STACK_SIZE_UNLIMITED){
    // bound the size 
    NSAssert([MCViewModel sharedModel].stackSize > 0, @"stack size must be positive");
    
    if ([MCViewModel sharedModel].historyStack.count >= [MCViewModel sharedModel].stackSize  && [MCViewModel sharedModel].historyStack > 0){
      [[MCViewModel sharedModel].historyStack removeObjectAtIndex:0]; // remove the first object to keep the stack size bounded
    }
  }
  
  // add the new object on the stack
  [[[MCViewModel sharedModel] historyStack] addObject:intent];
}

-(MCIntent*)popHistoryStack{
  NSAssert([MCViewModel sharedModel].historyStack.count > 0, @"something should be on the stack");
  
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
#ifdef DEBUG
    if (previousIntent == nil){
      if ([MCViewModel sharedModel].stackSize == STACK_SIZE_DISABLED){
        NSLog(@"Cannot pop an empty stack because the stack size is set to STACK_SIZE_DISABLED. You should assign [MCViewModel sharedModel].stackSize on startup.");
      }else if ([MCViewModel sharedModel].stackSize == STACK_SIZE_UNLIMITED){
        NSLog(@"Navigating back in the history stack too many times. You can check for an empty history stack by inspecting [MCViewModel sharedModel].historyStack.count > 1");
      }else if ([MCViewModel sharedModel].stackSize > 0){
        NSLog(@"Cannot pop an empty stack. Perhaps your stack size = %d is too small? You should check [MCViewModel sharedModel].stackSize", [MCViewModel sharedModel].stackSize);
      }else{
        NSLog(@"Unexpected stack size. Please ticket this problem to the developers.");
      }
    }
#endif
    NSAssert(previousIntent != nil, @"Cannot pop an empty history stack.");

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
//      sectionVC = (MCSectionViewController*) [self forceLoadViewController:[intent sectionName]];
      vc = (MCViewController*) [self forceLoadViewController:[intent viewName]];
    }
  }else{
    // edge case: transitioning from itself to itself, need to create a new view
    if (sectionVC == currentSectionVC){
      sectionVC = (MCSectionViewController*) [self forceLoadViewController:[intent sectionName]];
    }
  }

  // save changes to the previous intent
  // automatically propagates onPause to its child view
  if (currentSectionVC){
    // reset debug flags
    currentSectionVC.debugTag = NO;
    if (currentSectionVC.currentViewVC)
      currentSectionVC.currentViewVC.debugTag = NO;
    
//    NSLog(@"Pause %@", activeIntent);
    [currentSectionVC onPause:activeIntent];
    
#ifdef DEBUG
    if (!currentSectionVC.debugTag)
      NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onPause:intent] called", currentSectionVC);
    if (currentSectionVC.currentViewVC && !currentSectionVC.currentViewVC.debugTag)
      NSLog(@"Subclass %@ of MCViewController did not have its [super onPause:intent] called", currentSectionVC.currentViewVC);
#endif
  }

  // switch the views
  [self loadNewSection:sectionVC andView:vc withIntent:intent];
  
  // reset debug flags
  currentSectionVC.debugTag = NO;
  if (currentSectionVC.currentViewVC)
    currentSectionVC.currentViewVC.debugTag = NO;

  // resume on the section will also resume the view
  activeIntent = intent;
  [sectionVC onResume:intent];
//  NSLog(@"Resume %@", intent);
  
#ifdef DEBUG
  if (!currentSectionVC.debugTag)
    NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onResume:intent] called", currentSectionVC);
  if (currentSectionVC.currentViewVC && !currentSectionVC.currentViewVC.debugTag)
    NSLog(@"Subclass %@ of MCViewController did not have its [super onResume:intent] called", currentSectionVC.currentViewVC);
#endif
}

-(void)loadNewSection:(MCSectionViewController*)sectionVC andView:(MCViewController*)viewVC withIntent:(MCIntent*)intent{
  int transitionStyle = [intent animationStyle];
  
  if (currentSectionVC != sectionVC){ // replace the section VC
//        NSLog(@"Different section");
    [self addChildViewController:sectionVC];
    sectionVC.view.hidden = NO;
    CGRect rect = sectionVC.view.frame;
    rect.origin = CGPointMake(0, 0);
    rect.size = self.view.frame.size;
    [sectionVC.view setFrame:rect];
    [self.view addSubview:sectionVC.view];


    MCSectionViewController* oldSectionVC = currentSectionVC;
    [oldSectionVC.currentViewVC resignFirstResponder];
    [oldSectionVC resignFirstResponder];
    
    // opResult becomes true when an animation is applied, then we don't need to call our other animation code
//    BOOL opResult = [MCViewFactory applyTransitionToView:self.view transition:transitionStyle];
    BOOL opResult = [MCViewFactory applyTransitionFromView:currentSectionVC.view toView:sectionVC.view transition:transitionStyle completion:^{
      if (oldSectionVC != currentSectionVC){
        [oldSectionVC.view removeFromSuperview];
        [oldSectionVC removeFromParentViewController];
      }
    }];
    
    
    if (!opResult && currentSectionVC.view != sectionVC.view){ // if animation was not applied
      [UIView transitionFromView:currentSectionVC.view toView:sectionVC.view duration:0.25 options:(transitionStyle | UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
        if (oldSectionVC != currentSectionVC){
          [oldSectionVC.view removeFromSuperview];
          [oldSectionVC removeFromParentViewController];
        }
      }];
    }
    
    NSAssert(self.view.subviews.count < 5, @"clearing the view stack");
    
    
    // reset the animation style, don't animate the view if the section has already been animated
    transitionStyle = UIViewAnimationOptionTransitionNone;
  }else{
//    NSLog(@"Same section");
  }
  
  // load the view inside the section
  MCViewController* oldViewVC = sectionVC.currentViewVC;
  
  // if the view controller is the same as before, don't load it again
  if (oldViewVC != viewVC){
//        NSLog(@"different view");
    [oldViewVC resignFirstResponder];
  
    if (viewVC){
//          NSLog(@"attach view to section");
      
      [sectionVC addChildViewController:viewVC];
      viewVC.view.hidden = NO;
      CGRect rect = viewVC.view.frame;
      rect.origin = CGPointMake(0, 0);
      rect.size = sectionVC.innerView.bounds.size;
      [viewVC.view setFrame:rect];
      [sectionVC.innerView addSubview:viewVC.view];

      BOOL opResult = [MCViewFactory applyTransitionFromView:oldViewVC.view toView:viewVC.view transition:transitionStyle completion:^{
        if (sectionVC.currentViewVC != oldViewVC){
          [oldViewVC.view removeFromSuperview];
          [oldViewVC removeFromParentViewController];
        }
      }];

      if (oldViewVC.view != viewVC.view && !opResult){
        
        [UIView transitionFromView:oldViewVC.view toView:viewVC.view duration:0.250 options:(transitionStyle |UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
          if (sectionVC.currentViewVC != oldViewVC){
          [oldViewVC.view removeFromSuperview];
          [oldViewVC removeFromParentViewController];
          }
        }];
      }
    } else { // no view controller
//      NSLog(@"remove view from section");
      
      [oldViewVC.view removeFromSuperview];
      [oldViewVC removeFromParentViewController];
    }
  
    NSAssert(sectionVC.innerView.subviews.count < 5, @"clearing the view stack");
  }else{
//    NSLog(@"same view");
//    NSAssert([[sectionVC.innerView subviews] containsObject:oldViewVC.view], @"view should already be shown");
  }
    
  currentSectionVC = sectionVC;
  currentSectionVC.currentViewVC = viewVC;
}

-(void)clearView:(UIViewController*) view {
	for (UIViewController *vc in view.childViewControllers) {
    [vc.view resignFirstResponder]; // close the keyboard
		[vc.view removeFromSuperview];
	}
	
  [view.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
  
}

@end
