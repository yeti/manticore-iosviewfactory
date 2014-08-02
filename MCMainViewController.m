//
//  MCMainViewController.m
//  Manticore iOSViewFactory
//
//  Created by Richard Fung on 1/22/13.
//  Reworked, refactored and commented by Philippe Bertin on August 1, 2014
//  Copyright (c) 2014 Yeti LLC. All rights reserved.
//

#import "MCViewController.h"
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
 Register listeners to repsond to MCViewManager changes
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // register to listeners on model changes
        [[MCViewManager sharedManager] addObserver:self forKeyPath:@"currentIntent" options: NSKeyValueObservingOptionNew context: nil];
        [[MCViewManager sharedManager] addObserver:self forKeyPath:@"errorDict" options: NSKeyValueObservingOptionNew context: nil];
        [[MCViewManager sharedManager] addObserver:self forKeyPath:@"screenOverlay" options: NSKeyValueObservingOptionNew context: nil];
        [[MCViewManager sharedManager] addObserver:self forKeyPath:@"screenOverlays" options: NSKeyValueObservingOptionNew context: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushViewCache:) name:@"MCMainViewController_flushViewCache" object:[MCViewManager sharedManager]];
    }
    return self;
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

// Selector called when MCViewManager flushViewCache's method is called.
-(void)flushViewCache:(NSNotification *)notification
{
    dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
}

// ----------------------------------------------------------------------------
// Modified value changes are observed from MCViewManager :
//      - currentIntent
//      - errorDict
//      - screenOverlay
//      - screenOverlays
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentIntent"])
    {
        manticore_runOnMainQueueWithoutDeadlocking(^{
            [self goToIntent:[object valueForKeyPath:keyPath]];
        });
    
    } else if ([keyPath isEqualToString:@"errorDict"])
    {
        manticore_runOnMainQueueWithoutDeadlocking(^{
            if (!errorVC)
            {
#warning deal with custom error controllers
                errorVC = (MCErrorViewController*) [[MCViewManager sharedManager] createViewController:VIEW_BUILTIN_ERROR];
            }
            
            // remove from the previous
            [errorVC.view removeFromSuperview];
            [errorVC removeFromParentViewController];

            // set up
            [errorVC loadLatestErrorMessageWithDictionary:[object valueForKeyPath:keyPath]];

            // add to the current
            [errorVC.view setFrame:[self.view bounds]];
            [self.view addSubview: errorVC.view];

            [currentSectionVC.currentViewVC.view resignFirstResponder];
            [currentSectionVC.view resignFirstResponder];


            [errorVC becomeFirstResponder]; // make the error dialog the first responder
          
        });
  
    } else if ([keyPath isEqualToString:@"screenOverlay"])
    {
        manticore_runOnMainQueueWithoutDeadlocking(^{
          
            [self overlaySlideshow:@[[MCViewManager sharedManager].screenOverlay]];
            
        });
      
    } else if ([keyPath isEqualToString:@"screenOverlays"]){
      
        manticore_runOnMainQueueWithoutDeadlocking(^{
            [self overlaySlideshow:[MCViewManager sharedManager].screenOverlays];
        });
      
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
  
}

# pragma mark - Callback methods

// -------------------------------------------------------------------------------
// Callback method for transitioning to a new intent
// 1.
//
- (void) goToIntent: (MCIntent*) intent {
    
    /* 1. handle the history stack */
    intent = [self loadIntentAndHandleHistoryStack:intent];
    if (!intent)
        return;
    
    /* load the appropriate section from cache */
    MCSectionViewController* sectionVC =  (MCSectionViewController*)  [self loadOrCreateViewController:[intent sectionName]];
    NSAssert([sectionVC isKindOfClass:[MCSectionViewController class]], @"sections should be subclasses of MCSectionViewController");
    
    
    // Load appropriate view-controller associated with intent
    MCViewController* vc = nil;
    if ([intent viewName])
    {
        vc = (MCViewController*) [self loadOrCreateViewController:[intent viewName]];
        
        // Add that it shouldn't a MCSectionViewController which subclasses MCViewController
        NSAssert([vc isKindOfClass:[MCViewController class]], @"views should be subclasses of MCViewController");
        
        /* edge case: everything we are transitioning to is the same as the previous, need to create a new view */
        // Same section same view
        if (sectionVC == currentSectionVC && vc == currentSectionVC.currentViewVC)
        {
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
    
    // 3. switch the views
    [self loadNewSection:sectionVC andView:vc withIntent:intent];
    
    // reset debug flags
    currentSectionVC.debugTag = NO;
    if (currentSectionVC.currentViewVC)
        currentSectionVC.currentViewVC.debugTag = NO;
    
    // 4.resume on the section will also resume the view
    activeIntent = intent;
    [sectionVC onResume:intent];
    
#ifdef DEBUG
    if (!currentSectionVC.debugTag)
        NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onResume:intent] called", currentSectionVC);
    if (currentSectionVC.currentViewVC && !currentSectionVC.currentViewVC.debugTag)
        NSLog(@"Subclass %@ of MCViewController did not have its [super onResume:intent] called", currentSectionVC.currentViewVC);
#endif
}

-(void)overlaySlideshow:(NSArray*)overlays
{
    screenOverlaySlideshow = overlays;
    
    if (!overlays || overlays.count == 0)
    {
        if (screenOverlayButton)
        {
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
    if (!screenOverlayButton)
    {
        // set up the geometry of the new screen overlay
        CGRect rect = [self.view bounds];
        screenOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        screenOverlayButton.frame = rect;
        screenOverlayButton.contentMode = UIViewContentModeScaleToFill;
    }
    
    // this code will load 2 images on iPhone 5, one for the small screen and another image for the large screen
    
    // automatically remove the .png/.PNG extension
    NSString* overlayName = [overlays objectAtIndex:0];
    if ([[overlayName pathExtension] compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
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
        if ([UIImage imageNamed:overlayName])
        {
            imgOverlay = [UIImage imageNamed:overlayName];
        }
    }
    
    // show the new overlay
    if (imgOverlay)
    {
        [screenOverlayButton setImage:imgOverlay forState:UIControlStateNormal];
        screenOverlayButton.adjustsImageWhenHighlighted = NO;
        
        [screenOverlayButton addTarget:self action:@selector(overlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        if (![self.view.subviews containsObject:screenOverlayButton])
        {
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
        NSAssert(false, @"Screen overlay not found: %@", [MCViewManager sharedManager].screenOverlay);
#endif
    }
    
}

# pragma mark - Helper methods
# pragma mark  Load intent helper methods


// ----------------------------------------------------------------------------------------
// Handles intent and maintains the history stack
//
-(MCIntent*)loadIntentAndHandleHistoryStack:(MCIntent*)intent
{
    
    /* Handles SECTION_LAST (->1) &  SECTION_REWIND (->2) */
    /*----------------------------------------------------*/
    if ([[intent sectionName] isEqualToString:SECTION_LAST] || [[intent sectionName] isEqualToString:SECTION_REWIND]) {
        // Here we want to keep the savedInstanceState, without the SECTION or VIEW
        NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[intent savedInstanceState]];
        [savedState removeObjectForKey:@"viewName"]; // unusual design decision, sectionName is not saved in the savedState object
        
        // when  copying state values from the given intent, e.g., animation transition, to the old bundle
        int popNum = 1;
        
        //we can possibly add x2 x3 etc to this as well
        if ([[intent sectionName] isEqualToString:SECTION_REWIND]) {
            popNum = 2;
        }
        // try to get previous instance
        MCIntent* previousIntent = [self popHistoryStack: popNum];
#ifdef DEBUG
        if (previousIntent == nil){
            if ([MCViewManager sharedManager].stackSize == STACK_SIZE_DISABLED){
                NSLog(@"Cannot pop an empty stack because the stack size is set to STACK_SIZE_DISABLED. You should assign [MCViewManager sharedManager].stackSize on startup.");
            } else if ([MCViewManager sharedManager].stackSize == STACK_SIZE_UNLIMITED){
                NSLog(@"Navigating back in the history stack too many times. You can check for an empty history stack by inspecting [MCViewManager sharedManager].historyStack.count > 1");
            } else if ([MCViewManager sharedManager].stackSize > 0){
                NSLog(@"Cannot pop an empty stack. Perhaps your stack size = %d is too small? You should check [MCViewManager sharedManager].stackSize", [MCViewManager sharedManager].stackSize);
            } else {
                NSLog(@"Unexpected stack size. Please ticket this problem to the developers.");
            }
        }
#endif
        NSAssert(previousIntent != nil, @"Cannot pop an empty history stack.");
        
        // Assert just before ... remove this
        if (previousIntent == nil){
            // default behaviour is to stop changing intents, the current intent is set to an improper state
            return nil;
        }
        
        // replace the intent on the history stack
        [[previousIntent savedInstanceState] setValuesForKeysWithDictionary:savedState];
        return previousIntent;
    }
    
    /*          Handles SECTION_HISTORICAL (->1+)         */
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

-(MCViewController*) forceLoadViewController:(NSString*)sectionOrViewName
{
    // create global view cache if it doesn't already exist
    if (!dictCacheView){
        dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    // create the view controller
    MCViewController* vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
    NSAssert(vc != nil, @"VC should exist");
    [vc onCreate];
    
    //
    [dictCacheView setObject:vc forKey:sectionOrViewName];
    return vc;
}


// ---------------------------------------------------------------------------------------
// Adds the intent to the history stack, making sure to keep the stack size bounded
//
-(void)pushToHistoryStack:(MCIntent*)intent
{
    if ([MCViewManager sharedManager].stackSize == STACK_SIZE_DISABLED){
        // don't save anything to the stack
        return;
    }else if ([MCViewManager sharedManager].stackSize != STACK_SIZE_UNLIMITED){
        // bound the size
        NSAssert([MCViewManager sharedManager].stackSize > 0, @"stack size must be positive");
        
        if ([MCViewManager sharedManager].historyStack.count >= [MCViewManager sharedManager].stackSize  && [MCViewManager sharedManager].historyStack > 0){
            [[MCViewManager sharedManager].historyStack removeObjectAtIndex:0]; // remove the first object to keep the stack size bounded
        }
    }
    
    // add the new object on the stack
    [[[MCViewManager sharedManager] historyStack] addObject:intent];
}


// ---------------------------------------------------------------------------------------
// Goes back in historyStack "popNum" times.
// Starting from 1, meaning back to previous intent.
//
-(MCIntent*)popHistoryStack: (int) popNum
{
    NSAssert([MCViewManager sharedManager].historyStack.count > 0, @"something should be on the stack");
    
    //Make sure popNum isn't bigger than stack !!
    
    MCIntent* retIntent = nil;
    for (int i =0; i <= popNum; i++){
        if ([MCViewManager sharedManager].historyStack.count > 0 && i != popNum){
            [[MCViewManager sharedManager].historyStack removeLastObject]; // this is the shown view, we don't want to stay on this view so discard it
            retIntent = [[MCViewManager sharedManager].historyStack lastObject];
        } else {
            return retIntent;
        }
    }
    
    return nil; // nothing on the history stack
}

-(MCIntent*)getHistoricalIntentAtIndex: (int) historyNum
{
    NSAssert([MCViewManager sharedManager].historyStack.count > historyNum, @"something should be on the stack");
    
    MCIntent* retIntent = nil;
    
    retIntent = [[MCViewManager sharedManager].historyStack objectAtIndex: historyNum];
    
    [[MCViewManager sharedManager].historyStack removeObjectAtIndex:historyNum];
    
    //  NSRange r;
    //  r.location = historyNum;
    //  r.length = [[MCViewManager sharedManager].historyStack count] - historyNum;
    //
    //  [[MCViewManager sharedManager].historyStack  removeObjectsInRange: r];
    
    return retIntent;
}


-(MCViewController*) loadOrCreateViewController:(NSString*)sectionOrViewName
{
    // create global view cache if it doesn't already exist
    if (!dictCacheView)
    {
        dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    // test for existence
    MCViewController* vc = [dictCacheView objectForKey:sectionOrViewName];
    if (vc == nil)
    {
        // create the view controller
        vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
        NSAssert(vc != nil, @"VC should exist");
        
        [vc onCreate];
        [dictCacheView setObject:vc forKey:sectionOrViewName];
    }
    
    return vc;
    
}



// ----------------------------------------------------------------------------------------
// This method deals with switching the view during a transition
// Section may be the same, or may not.
// View may be the same, or may not
//
//
-(void)loadNewSection:(MCSectionViewController*)sectionVC andView:(MCViewController*)viewVC withIntent:(MCIntent*)intent
{
    
    // We get the wanted transition
    int transitionStyle = [intent animationStyle];
    
    //NSLog(@" Section : %i", transitionStyle);
    
    
    
    // 1. If the section we are going to show is different from the current one :
    //
    //      1.1. Add new Section as Child-ViewController to self
    //      1.2. Set the new Section's properties
    //      1.3. For pop animations, the new section's view has to come from behind the old view.
    //      1.4. Get a pointer to the future oldSection and resign it as first responder
    //      1.5. We apply our custom transition (or not) : in accordance with "transitionStyle".
    //      1.5.1. After completion, oldSectionVC has to be different than currentSectionVC but we make sure it is.
    //      1.5.2. Custom transition was applied, we can now remove the old Section and it's view
    //      1.6. Custom transition was not applied. If the old/new view are different then apply standard UITransition.
    //      1.6.1. Again we make sure old and new sections were different before transition so they should still be after.
    //      1.7. Reset the animation style to none. If a transition already applied on the section, no need to apply it again on VC.
    //
    //
    
    // 1.
    if (currentSectionVC != sectionVC ){
        // 1.1
        [self addChildViewController:sectionVC];
        
        // 1.2
        CGRect rect;
        rect.origin = CGPointMake(0, 0);
        rect.size = self.view.frame.size;
        [sectionVC.view setFrame:rect];
        [sectionVC.view setHidden: false];
        
        // 1.3
        if (transitionStyle == ANIMATION_POP || transitionStyle == ANIMATION_POP_LEFT)
        {
            [self.view insertSubview:sectionVC.view belowSubview:currentSectionVC.view];
        } else {
            [self.view addSubview:sectionVC.view];
        }
        
        // 1.4
        MCSectionViewController* oldSectionVC = currentSectionVC;
        [oldSectionVC.currentViewVC resignFirstResponder];
        [oldSectionVC resignFirstResponder];
        
        // 1.5 : Returns True if our custom animation was applied.
        BOOL transitionApplied = [MCMainViewController applyTransitionFromView:oldSectionVC.view toView:sectionVC.view transition:transitionStyle completion:^{
            
            // 1.5.1
            if (oldSectionVC != currentSectionVC)
            {
                // 1.5.2
                [oldSectionVC.view removeFromSuperview];
                [oldSectionVC removeFromParentViewController];
            }
        }];
        
        // 1.6
        if (!transitionApplied && oldSectionVC.view != sectionVC.view)
        {
            transitionApplied = true;
            [UIView transitionFromView:oldSectionVC.view toView:sectionVC.view duration:0.25 options:(transitionStyle | UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
                
                // 1.6.1.
                if (oldSectionVC != currentSectionVC)
                {
                    [oldSectionVC.view removeFromSuperview];
                    [oldSectionVC removeFromParentViewController];
                }
            }];
        }
        
        // 1.7
        transitionStyle = UIViewAnimationOptionTransitionNone;
    }
    
    
    
    
    // 2. We only want to load the "new" view if it is new -> if it was not the section's currentView the last time the section was shown.
    //      In any other cases, we need to load the view and place it as the section's currentView.
    //
    //      2.1. It is different. We can resign it as first responder to prepare for new view
    //      2.2. viewVC not nil, we can process it
    //      2.2.1. Add the new VC (viewVC) as childVC of it's Section
    //      2.2.2. Set the new VC's properties
    //      2.2.3. For pop animations, the new view has to come from behind the old view.
    //      2.2.4. See "1.5"
    //      2.2.5. See "1.6"
    //      2.3. viewVC is nil, we transition to a section without view
    //
  
    // We get a pointer the the section's old "currentView".
    MCViewController* sectionVC_oldCurrentViewVC = sectionVC.currentViewVC;
  
    // 2.
    if (sectionVC_oldCurrentViewVC != viewVC)
    {
        // 2.1
        [sectionVC_oldCurrentViewVC resignFirstResponder];
    
        // 2.2
        if (viewVC)
        {
            // 2.2.1
            [sectionVC addChildViewController:viewVC];
      
            // 2.2.2
            CGRect rect;
            rect.origin = CGPointMake(0, 0);
            rect.size = sectionVC.innerView.bounds.size;
            [viewVC.view setHidden: NO];
            [viewVC.view setFrame:rect];
            
            // 2.2.3
            if (transitionStyle == ANIMATION_POP || transitionStyle == ANIMATION_POP_LEFT)
            {
                [sectionVC.innerView insertSubview:viewVC.view belowSubview:sectionVC_oldCurrentViewVC.view];
            } else {
                [sectionVC.innerView addSubview:viewVC.view];
            }
      
      
            // 2.2.4
            BOOL opResult = [MCMainViewController applyTransitionFromView:sectionVC_oldCurrentViewVC.view toView:viewVC.view transition:transitionStyle completion:^{
        
                if (sectionVC.currentViewVC != sectionVC_oldCurrentViewVC)
                {
                    [sectionVC_oldCurrentViewVC.view removeFromSuperview];
                    [sectionVC_oldCurrentViewVC removeFromParentViewController];
                }
            }];
      
            //2.2.5
            if (sectionVC_oldCurrentViewVC.view != viewVC.view && !opResult){
        
                [UIView transitionFromView:sectionVC_oldCurrentViewVC.view toView:viewVC.view duration:0.50 options:(transitionStyle |UIViewAnimationOptionShowHideTransitionViews) completion:^(BOOL finished) {
                    if (sectionVC.currentViewVC != sectionVC_oldCurrentViewVC)
                    {
                        [sectionVC_oldCurrentViewVC.view removeFromSuperview];
                        [sectionVC_oldCurrentViewVC removeFromParentViewController];
                    }
                }];
            }
        }
        // 2.3
        else
        {
            [sectionVC_oldCurrentViewVC.view removeFromSuperview];
            [sectionVC_oldCurrentViewVC removeFromParentViewController];
        }
    
        
        // Why ???
        NSAssert(sectionVC.innerView.subviews.count < 5, @"clearing the view stack");
    }
  
    // We applied the transitions so we can now set the new (or not) section and new (or not) view.
    currentSectionVC = sectionVC;
    currentSectionVC.currentViewVC = viewVC;
}




- (void)overlayButtonPressed:(id)sender
{
    NSMutableArray* newArray = [NSMutableArray arrayWithArray:screenOverlaySlideshow];
    if (newArray.count > 0)
    {
        [newArray removeObjectAtIndex:0];
    }
    screenOverlaySlideshow = newArray;
    [self overlaySlideshow:newArray];
}




#pragma mark - 
#pragma mark - Utils

// -------------------------------------------------------------------------------------------
// this method offers custom animations that are not provided by UIView, mainly the
// slide left and right animations (no idea why Apple separated these animations)
//
// The boolean returns true if our animations were asked (and therefore applied).
//
+(BOOL)applyTransitionFromView:(UIView*)oldView toView:(UIView*)newView transition:(int)transitionValue completion:(void (^)(void))completion  {
    
    // Get all the necessary positions to apply the custom transitions
    
    CGPoint finalPosition = oldView.center;
    CGPoint leftPosition = CGPointMake(-oldView.frame.size.width + finalPosition.x, finalPosition.y);
    CGPoint rightPosition = CGPointMake(finalPosition.x + oldView.frame.size.width, finalPosition.y);
    
    CGPoint closerLeftPosition = CGPointMake(finalPosition.x - 40, finalPosition.y);
    CGPoint closerRightPosition = CGPointMake(finalPosition.x + 40, finalPosition.y);
    
    
    CGPoint topPosition = CGPointMake(finalPosition.x, finalPosition.y + oldView.frame.size.height);
    CGPoint bottomPosition = CGPointMake(finalPosition.x, -oldView.frame.size.height + finalPosition.y);
    
    
    // Returns true if "transitionValue" applies to our own transitions.
    // Return false otherwise.
    
    switch (transitionValue) {
            
        case ANIMATION_PUSH:
        {
            newView.center = rightPosition;
            oldView.center = finalPosition;
            
            [UIView animateWithDuration:0.5 animations:^{
                newView.center = finalPosition;
                oldView.center = closerLeftPosition;
                
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        case ANIMATION_PUSH_LEFT:
        {
            newView.center = leftPosition;
            oldView.center = finalPosition;
            
            [UIView animateWithDuration:0.5 animations:^{
                newView.center = finalPosition;
                oldView.center = closerRightPosition;
                
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        case ANIMATION_POP:
        {
            newView.center = closerLeftPosition;
            oldView.center = finalPosition;
            
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
                newView.center = finalPosition;
                oldView.center = rightPosition;
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        case ANIMATION_POP_LEFT:
        {
            newView.center = closerRightPosition;
            oldView.center = finalPosition;
            
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
                newView.center = finalPosition;
                oldView.center = leftPosition;
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        case ANIMATION_SLIDE_FROM_BOTTOM:
        {
            newView.center = topPosition;
            
            [UIView animateWithDuration:0.5 animations:^{
                newView.center = finalPosition;
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        case ANIMATION_SLIDE_FROM_TOP:
        {
            newView.center = bottomPosition;
            
            [UIView animateWithDuration:0.5 animations:^{
                newView.center = finalPosition;
            } completion:^(BOOL finished) {
                completion();
                oldView.center = finalPosition;
            }];
            return YES;
            break;
        }
            
            
        default:
        {
            return NO;
            break;
        }
    }
}


@end
