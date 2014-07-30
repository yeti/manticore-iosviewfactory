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
#import "MCViewManager.h"



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


/* 
 Register listeners to repsond to MCViewModel changes
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
      // register to listeners on model changes
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"currentIntent" options: NSKeyValueObservingOptionNew context: nil];
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"errorDict" options: NSKeyValueObservingOptionNew context: nil];
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"screenOverlay" options: NSKeyValueObservingOptionNew context: nil];
      [[MCViewModel sharedModel] addObserver:self forKeyPath:@"screenOverlays" options: NSKeyValueObservingOptionNew context: nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushViewCache:) name:@"MCMainViewController_flushViewCache" object:[MCViewModel sharedModel]];
        // last parameter filters the response
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

/*
 This method directs to the appropriate responders for the changes made to the MCViewModel
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"currentIntent"]) {
      manticore_runOnMainQueueWithoutDeadlocking(^{
        [self goToIntent:[MCViewModel sharedModel].currentIntent];
      });
    
  } else if ([keyPath isEqualToString:@"errorDict"]) {
      manticore_runOnMainQueueWithoutDeadlocking(^{
          if (!errorVC) {
          errorVC = (MCErrorViewController*) [[MCViewManager sharedManager] createViewController:VIEW_BUILTIN_ERROR];
          }
        
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
  
  } else if ([keyPath isEqualToString:@"screenOverlay"]) {
      
      manticore_runOnMainQueueWithoutDeadlocking(^{
        
          [self overlaySlideshow:@[[MCViewModel sharedModel].screenOverlay]];
        
      });
      
  } else if ([keyPath isEqualToString:@"screenOverlays"]){
      
      manticore_runOnMainQueueWithoutDeadlocking(^{
          [self overlaySlideshow:[MCViewModel sharedModel].screenOverlays];
      });
      
  } else {
      [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
  
}

# pragma mark - Callback methods

// -------------------------------------------------------------------------------
// Callback method for transitioning to a new intent
//
- (void) goToIntent: (MCIntent*) intent {
    
    /* handle the history stack */
    intent = [self loadIntentAndHandleHistoryStack:intent];
    if (!intent)
        return;
    
    /* load the appropriate section from cache */
    MCSectionViewController* sectionVC =  (MCSectionViewController*)  [self loadOrCreateViewController:[intent sectionName]];
    NSAssert([sectionVC isKindOfClass:[MCSectionViewController class]], @"sections should be subclasses of MCSectionViewController");
    
    MCViewController* vc = nil;
    if ([intent viewName]){
        vc = (MCViewController*) [self loadOrCreateViewController:[intent viewName]];
        NSAssert([vc isKindOfClass:[MCViewController class]], @"views should be subclasses of MCViewController");
        
        /* edge case: everything we are transitioning to is the same as the previous, need to create a new view */
        if (sectionVC == currentSectionVC && vc == currentSectionVC.currentViewVC){
            vc = (MCViewController*) [self forceLoadViewController:[intent viewName]];
        }
    } else {
        /* edge case: transitioning from itself to itself, need to create a new view */
        if (sectionVC == currentSectionVC){
            sectionVC = (MCSectionViewController*) [self forceLoadViewController:[intent sectionName]];
        }
    }
    
    /*
     save changes to the previous intent
     automatically propagates onPause to its child view
     */
    if (currentSectionVC){
        /* reset debug flags */
        currentSectionVC.debugTag = NO;
        if (currentSectionVC.currentViewVC)
            currentSectionVC.currentViewVC.debugTag = NO;
        
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
    
#ifdef DEBUG
    if (!currentSectionVC.debugTag)
        NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onResume:intent] called", currentSectionVC);
    if (currentSectionVC.currentViewVC && !currentSectionVC.currentViewVC.debugTag)
        NSLog(@"Subclass %@ of MCViewController did not have its [super onResume:intent] called", currentSectionVC.currentViewVC);
#endif
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
      screenOverlayButton.adjustsImageWhenHighlighted = NO;

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

# pragma mark - Helper methods
# pragma mark  Load intent helper methods


// ----------------------------------------------------------------------------------------
// Handles intent and maintains the history stack
//
-(MCIntent*)loadIntentAndHandleHistoryStack:(MCIntent*)intent{
    
    /* Handles SECTION_LAST (->1) &  SECTION_REWIND (->2) */
    /*----------------------------------------------------*/
    if ([[intent sectionName] isEqualToString:SECTION_LAST] || [[intent sectionName] isEqualToString:SECTION_REWIND]) {
        // Here we want to keep the savedInstanceState, without the SECTION or VIEW as 
        NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[intent savedInstanceState]];
        [savedState removeObjectForKey:@"viewName"]; // unusual design decision, sectionName is not saved in the savedState object
        
        // when  copying state values from the given intent, e.g., animation transition, to the old bundle
        int popNum = 1;
        
        //we can possibly add x2 x3 etc to this as well
        if ([[intent sectionName] isEqualToString:SECTION_REWIND]) {
            popNum = 2;
        }
        MCIntent* previousIntent = [self popHistoryStack: popNum];
#ifdef DEBUG
        if (previousIntent == nil){
            if ([MCViewModel sharedModel].stackSize == STACK_SIZE_DISABLED){
                NSLog(@"Cannot pop an empty stack because the stack size is set to STACK_SIZE_DISABLED. You should assign [MCViewModel sharedModel].stackSize on startup.");
            } else if ([MCViewModel sharedModel].stackSize == STACK_SIZE_UNLIMITED){
                NSLog(@"Navigating back in the history stack too many times. You can check for an empty history stack by inspecting [MCViewModel sharedModel].historyStack.count > 1");
            } else if ([MCViewModel sharedModel].stackSize > 0){
                NSLog(@"Cannot pop an empty stack. Perhaps your stack size = %d is too small? You should check [MCViewModel sharedModel].stackSize", [MCViewModel sharedModel].stackSize);
            } else {
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
    }
    
    /*          Handles SECTION_HISTORICAL (->1)          */
    /*----------------------------------------------------*/
    else if([[intent sectionName] isEqualToString:SECTION_HISTORICAL]) {
      
      //we need to load the intent that is in this position in our history stack
      NSNumber *historyNum = [intent.savedInstanceState objectForKey: @"historyNumber"];
      
      MCIntent* previousIntent = [self getHistoricalIntentAtIndex: [historyNum intValue]];
      
      if (previousIntent == nil){
        // default behaviour is to stop changing intents, the current intent is set to an improper state
        return nil;
      }
      
      //removing the view name makes it so that the observer method doesnt try to create a new one
      
      NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[intent savedInstanceState]];
      [savedState removeObjectForKey:@"viewName"];
      [[previousIntent savedInstanceState] setValuesForKeysWithDictionary:savedState];
      
      [self pushToHistoryStack:previousIntent];
      
      //this process will grab the historical view, put it on top of the stack and remove it from its old location
      //the potential situation could happen where we want to jump back and remove everything since then
      //in that case we should create another similar workflow using a seperate SECTION constant called REVERT or something
      //maybe this workflow could change to REUSE
      
      return previousIntent;
      
    } else {
        // build the history stack
        [self pushToHistoryStack:intent];
    }
    
    return intent;
}

-(MCViewController*) forceLoadViewController:(NSString*)sectionOrViewName{
    // create global view cache if it doesn't already exist
    if (!dictCacheView){
        dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    // create the view controller
    MCViewController* vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
    NSAssert(vc != nil, @"VC should exist");
    [vc onCreate];
    [dictCacheView setObject:vc forKey:sectionOrViewName];
    return vc;
}


// ---------------------------------------------------------------------------------------
// Adds the intent to the history stack, making sure to keep the stack size bounded
//
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


// ---------------------------------------------------------------------------------------
// Goes back in historyStack "popNum" times.
// Starting from 1, meaning back to previous intent.
//
-(MCIntent*)popHistoryStack: (int) popNum{
  NSAssert([MCViewModel sharedModel].historyStack.count > 0, @"something should be on the stack");
  
  MCIntent* retIntent = nil;
  for (int i =0; i <= popNum; i++){
    if ([MCViewModel sharedModel].historyStack.count > 0 && i != popNum){
      [[MCViewModel sharedModel].historyStack removeLastObject]; // this is the shown view, we don't want to stay on this view so discard it
      retIntent = [[MCViewModel sharedModel].historyStack lastObject];
    } else {
      return retIntent;
    }
  }
  
  return nil; // nothing on the history stack
}

-(MCIntent*)getHistoricalIntentAtIndex: (int) historyNum{
  NSAssert([MCViewModel sharedModel].historyStack.count > historyNum, @"something should be on the stack");
  
  MCIntent* retIntent = nil;
  
  retIntent = [[MCViewModel sharedModel].historyStack objectAtIndex: historyNum];
  
  [[MCViewModel sharedModel].historyStack removeObjectAtIndex:historyNum];
  
//  NSRange r;
//  r.location = historyNum;
//  r.length = [[MCViewModel sharedModel].historyStack count] - historyNum;
//  
//  [[MCViewModel sharedModel].historyStack removeObjectsInRange: r];
  
  return retIntent;
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
    vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
    NSAssert(vc != nil, @"VC should exist");
    
    [vc onCreate];
    [dictCacheView setObject:vc forKey:sectionOrViewName];
  }

  return vc;
  
}

-(void)loadNewSection:(MCSectionViewController*)sectionVC andView:(MCViewController*)viewVC withIntent:(MCIntent*)intent{
    
    int transitionStyle = [intent animationStyle];
  
    // replace the section VC
    if (currentSectionVC != sectionVC ){
    
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
        BOOL opResult = [MCViewManager applyTransitionFromView:currentSectionVC.view toView:sectionVC.view transition:transitionStyle completion:^{

            if (oldSectionVC != currentSectionVC) {
                [oldSectionVC.view removeFromSuperview];
                [oldSectionVC removeFromParentViewController];
            }
        }];
        
    // if animation was not applied
      if (!opResult && currentSectionVC.view != sectionVC.view) {
      
          [UIView transitionFromView:currentSectionVC.view toView:sectionVC.view duration:0.25 options:(transitionStyle | UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
              if (oldSectionVC != currentSectionVC){
                  [oldSectionVC.view removeFromSuperview];
                  [oldSectionVC removeFromParentViewController];
              }
          }];
      }
    
      //NSAssert(self.view.subviews.count < 5, @"clearing the view stack");
    
      // reset the animation style, don't animate the view if the section has already been animated
      transitionStyle = UIViewAnimationOptionTransitionNone;
  }
  
  // load the view inside the section
  MCViewController* oldViewVC = sectionVC.currentViewVC;
  
  // if the view controller is the same as before, don't load it again
  if (oldViewVC != viewVC){
    
    [oldViewVC resignFirstResponder];
    
    if (viewVC) {
      
      // THis is where I need to messa round.
      
      [sectionVC addChildViewController:viewVC];
      
      viewVC.view.hidden = NO;
      
      CGRect rect = viewVC.view.frame;
      rect.origin = CGPointMake(0, 0);
      
      rect.size = sectionVC.innerView.bounds.size;
      
      [viewVC.view setFrame:rect];
      NSLog(@"%i", transitionStyle);
      
      if (transitionStyle == ANIMATION_POP || transitionStyle == ANIMATION_POP_LEFT) {
        
        [sectionVC.innerView insertSubview:viewVC.view belowSubview:oldViewVC.view];
      } else {
        [sectionVC.innerView addSubview:viewVC.view];
      }
      
      
      BOOL opResult = [MCViewManager applyTransitionFromView:oldViewVC.view toView:viewVC.view transition:transitionStyle completion:^{
        
        if (sectionVC.currentViewVC != oldViewVC) {
          [oldViewVC.view removeFromSuperview];
          [oldViewVC removeFromParentViewController];
        }
      }];
      
      if (oldViewVC.view != viewVC.view && !opResult){
        
        [UIView transitionFromView:oldViewVC.view toView:viewVC.view duration:0.50 options:(transitionStyle |UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
          if (sectionVC.currentViewVC != oldViewVC){
            [oldViewVC.view removeFromSuperview];
            [oldViewVC removeFromParentViewController];
          }
        }];
      }
    } else { // no view controller
      
      [oldViewVC.view removeFromSuperview];
      [oldViewVC removeFromParentViewController];
    }
    
    NSAssert(sectionVC.innerView.subviews.count < 5, @"clearing the view stack");
  }
  
  currentSectionVC = sectionVC;
  currentSectionVC.currentViewVC = viewVC;
}

- (void)overlayButtonPressed:(id)sender{
  NSMutableArray* newArray = [NSMutableArray arrayWithArray:screenOverlaySlideshow];
  if (newArray.count > 0)
    [newArray removeObjectAtIndex:0];
  screenOverlaySlideshow = newArray;
  [self overlaySlideshow:newArray];
}

@end
