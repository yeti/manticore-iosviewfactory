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
#import "MCActivity.h"




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

@property (strong, nonatomic, readwrite) NSMutableDictionary *dictCacheView;
@property (strong, nonatomic, readwrite) MCErrorViewController* errorVC;
@property (strong, nonatomic, readwrite) MCSectionViewController* currentSectionVC;
@property (strong, nonatomic, readwrite) MCActivity* activeActivity;
@property (strong, nonatomic, readwrite) UIButton* screenOverlayButton;
@property (strong, nonatomic, readwrite) NSArray* screenOverlaySlideshow;

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
        [[MCViewManager sharedManager] addObserver:self forKeyPath:@"currentActivity" options: NSKeyValueObservingOptionNew context: nil];
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
  
    _dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
}

// Selector called when MCViewManager flushViewCache's method is called.
-(void)flushViewCache:(NSNotification *)notification
{
    _dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
}

// ----------------------------------------------------------------------------
// Modified value changes are observed from MCViewManager :
//      - currentActivity
//      - errorDict
//      - screenOverlay
//      - screenOverlays
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentActivity"])
    {
        manticore_runOnMainQueueWithoutDeadlocking(^{
            [self goToActivity:[object valueForKeyPath:keyPath]];
        });
    
    } else if ([keyPath isEqualToString:@"errorDict"])
    {
        manticore_runOnMainQueueWithoutDeadlocking(^{
            if (!_errorVC)
            {
#warning deal with custom error controllers
                _errorVC = (MCErrorViewController*) [[MCViewManager sharedManager] createViewController:VIEW_BUILTIN_ERROR];
            }
            
            // remove from the previous
            [_errorVC.view removeFromSuperview];
            [_errorVC removeFromParentViewController];

            // set up
            [_errorVC loadLatestErrorMessageWithDictionary:[object valueForKeyPath:keyPath]];

            // add to the current
            [_errorVC.view setFrame:[self.view bounds]];
            [self.view addSubview: _errorVC.view];

            [_currentSectionVC.currentViewVC.view resignFirstResponder];
            [_currentSectionVC.view resignFirstResponder];


            [_errorVC becomeFirstResponder]; // make the error dialog the first responder
          
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
// Callback method for transitioning to a new Activity
// 1. Handle the History Stack
// 2. Load/create the appropriate section associated with the activity
// 3. Load/create appropriate View associated with the activity
// 3.1. Activity is only associated with a Section
// 4. Propagation of onPause to the active Activity's childView before transitionning (-> for saving changes to previous activity)
//
//
- (void) goToActivity: (MCActivity*) activity {
    
    // 1.
    activity = [self loadActivityAndHandleHistoryStack:activity];
    if (!activity)
        return;
    
    // 2.
    MCSectionViewController* sectionVC =  (MCSectionViewController*)  [self loadOrCreateViewController:[activity associatedSectionName]];
    NSAssert([sectionVC isKindOfClass:[MCSectionViewController class]], @"Your section %@ should subclass MCSectionViewController", [sectionVC description]);
    
    // 3.
    MCViewController* vc = nil;
    if ([activity associatedViewName])
    {
        vc = (MCViewController*) [self loadOrCreateViewController:[activity associatedViewName]];
        
        // Add that it shouldn't a MCSectionViewController which subclasses MCViewController
        NSAssert([vc isKindOfClass:[MCViewController class]], @"Your view %@ should subclasses MCViewController", [vc description]);
        
        /* edge case: everything we are transitioning to is the same as the previous, need to create a new view */
        // Same section same view
        if (sectionVC == _currentSectionVC && vc == _currentSectionVC.currentViewVC)
        {
            vc = (MCViewController*) [self forceLoadViewController:[activity associatedViewName]];
        }
    }
    // 3.1.
    else
    {
        // If transitionning to same Section, we reload it anyway because the new Activity only has an associated Section
        if (sectionVC == _currentSectionVC)
        {
            sectionVC = (MCSectionViewController*) [self forceLoadViewController:[activity associatedSectionName]];
        }
    }
    
    // 4.
    if (_currentSectionVC)
    {
        // reset debug flags
        _currentSectionVC.debugTag = NO;
        if (_currentSectionVC.currentViewVC)
            _currentSectionVC.currentViewVC.debugTag = NO;
        
        [_currentSectionVC onPause:_activeActivity];
        
#ifdef DEBUG
        if (!_currentSectionVC.debugTag)
            NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onPause:activity] called", _currentSectionVC);
        if (_currentSectionVC.currentViewVC && !_currentSectionVC.currentViewVC.debugTag)
            NSLog(@"Subclass %@ of MCViewController did not have its [super onPause:activity] called", _currentSectionVC.currentViewVC);
#endif
    }
    
    // 3. switch the views
    [self loadNewSection:sectionVC andView:vc withActivity:activity];
    
    // reset debug flags
    _currentSectionVC.debugTag = NO;
    if (_currentSectionVC.currentViewVC)
        _currentSectionVC.currentViewVC.debugTag = NO;
    
    // 4.resume on the section will also resume the view
    _activeActivity = activity;
    [sectionVC onResume:activity];
    
#ifdef DEBUG
    if (!_currentSectionVC.debugTag)
        NSLog(@"Subclass %@ of MCSectionViewController did not have its [super onResume:activity] called", _currentSectionVC);
    if (_currentSectionVC.currentViewVC && !_currentSectionVC.currentViewVC.debugTag)
        NSLog(@"Subclass %@ of MCViewController did not have its [super onResume:activity] called", _currentSectionVC.currentViewVC);
#endif
}

-(void)overlaySlideshow:(NSArray*)overlays
{
    _screenOverlaySlideshow = overlays;
    
    if (!overlays || overlays.count == 0)
    {
        if (_screenOverlayButton)
        {
            // fade out the overlay in 200 ms
            _screenOverlayButton.alpha = 1.0;
            [UIView animateWithDuration:MANTICORE_OVERLAY_ANIMATION_DURATION animations:^{
                _screenOverlayButton.alpha = 0.0;
            } completion:^(BOOL finished) {
                [_screenOverlayButton resignFirstResponder];
                [_screenOverlayButton removeFromSuperview];
                _screenOverlayButton = nil;
            }];
        }
        return;
    }
    
    // load the overlay
    if (!_screenOverlayButton)
    {
        // set up the geometry of the new screen overlay
        CGRect rect = [self.view bounds];
        _screenOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _screenOverlayButton.frame = rect;
        _screenOverlayButton.contentMode = UIViewContentModeScaleToFill;
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
        [_screenOverlayButton setImage:imgOverlay forState:UIControlStateNormal];
        _screenOverlayButton.adjustsImageWhenHighlighted = NO;
        
        [_screenOverlayButton addTarget:self action:@selector(overlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        if (![self.view.subviews containsObject:_screenOverlayButton])
        {
            _screenOverlayButton.alpha = 0.0;
            [self.view addSubview:_screenOverlayButton ];
            [UIView animateWithDuration:MANTICORE_OVERLAY_ANIMATION_DURATION animations:^{
                _screenOverlayButton.alpha = 1.0;
            }];
        }
        [self.view bringSubviewToFront:_screenOverlayButton];
        [_screenOverlayButton becomeFirstResponder];
    }else{
#ifdef DEBUG
        NSAssert(false, @"Screen overlay not found: %@", [MCViewManager sharedManager].screenOverlay);
#endif
    }
    
}



#pragma mark - History Stack helper methods


//---------------------------------------------------------------------------
// Keys for private members : SectionName, ViewName and AnimationStyle in activityInfos Dictionary
#define kSectionName    @"__SectionName__"
#define kViewName       @"__ViewName__"
#define kAnimationStlye @"__AnimationStyle__"
// If activity is dynamic, its activityInfos will contain a dictionary for key kSearchInfos
#define kSearchInfos    @"__SearchInfos__"
#define kType           @"__Type__"


/**
 * This method loads the activity if dynamic request,
 * it also maintains the history stack.
 * @discussion For dynamic requests :
 * @discussion 1. Get savedInfos from activity
 * @discussion 2. Get a pointer to the activity we are looking for
 * @discussion 3. Populate the found activity with savedInfos
 * @discussion For Static activities : putActivityOnTopOfHistoryStack
 *
 */
-(MCActivity*)loadActivityAndHandleHistoryStack:(MCActivity*)activity
{
    // We first look if the activity is dynamic (-> need to find corresponding activity in history stack)
    if ([activity.activityInfos objectForKey:kSearchInfos])
    {
        // We will work on the dictionary to find the right method to apply to activity
        NSDictionary *searchInfos = [activity.activityInfos objectForKey:kSearchInfos];
        
        // We either want to make a pop or a push
        // Case push
        if ([[searchInfos objectForKey:kType] isEqualToString:@"push"])
        {
            
        }
        // Case pop
        else if ([[searchInfos objectForKey:kType] isEqualToString:@"pop"])
        {
            
        }
        else NSLog(@"Key for searchInfos is %@ : BUG in %s", [searchInfos objectForKey:kType], __func__);
    }
    
    // Activity is static, we can handle the Activity as is
    else
    {
        // build the history stack
        //[self putActivityOnTopOfHistoryStack:activity];
    }
    
    //return activity;
    
    
    
    /* Handles SECTION_LAST (->1) &  SECTION_REWIND (->2) */
    /*----------------------------------------------------*/
    if ([[activity associatedSectionName] isEqualToString:SECTION_LAST] || [[activity associatedSectionName] isEqualToString:SECTION_REWIND])
    {
        // Here we want to keep the activityInfos, without the SECTION or VIEW
        NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[activity activityInfos]];
        [savedState removeObjectForKey:kViewName];
        [savedState removeObjectForKey:kSectionName];
        
        // when  copying state values from the given activity, e.g., animation transition, to the old bundle
        int popNum = 1;
        
        //we can possibly add x2 x3 etc to this as well
        if ([[activity associatedSectionName] isEqualToString:SECTION_REWIND]) {
            popNum = 2;
        }
        // try to get previous instance
        MCActivity* previousActivity = [self popHistoryStack: popNum];
#ifdef DEBUG
        if (previousActivity == nil){
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
        
        NSAssert(previousActivity != nil, @"Cannot pop an empty history stack.");
        if (previousActivity == nil)
            return nil;
        
        // replace the Activity on the history stack
        [[previousActivity activityInfos] setValuesForKeysWithDictionary:savedState];
        return previousActivity;
    }
    
    /*          Handles SECTION_HISTORICAL (->1+)         */
    /*----------------------------------------------------*/
    else if([[activity associatedSectionName] isEqualToString:SECTION_HISTORICAL])
    {
        
        //we need to load the activity that is in this position in our history stack
        NSNumber *historyNum = [activity.activityInfos objectForKey: @"historyNumber"];
        
        MCActivity* previousActivity = [self getHistoricalActivityAtIndex: [historyNum intValue]];
        
        if (previousActivity == nil){
            // default behaviour is to stop changing Activities, the current Activity is set to an improper state
            return nil;
        }
        
        //removing the view name makes it so that the observer method doesnt try to create a new one
        
        NSMutableDictionary* savedState = [NSMutableDictionary dictionaryWithDictionary:[activity activityInfos]];
        [savedState removeObjectForKey:kSectionName];
        [savedState removeObjectForKey:kViewName];
        
        [[previousActivity activityInfos] setValuesForKeysWithDictionary:savedState];
        
        [self putActivityOnTopOfHistoryStack:previousActivity];
        
        //this process will grab the historical view, put it on top of the stack and remove it from its old location
        //the potential situation could happen where we want to jump back and remove everything since then
        //in that case we should create another similar workflow using a seperate SECTION constant called REVERT or something
        //maybe this workflow could change to REUSE
        
        return previousActivity;
        
    } else
    {
        // build the history stack
        [self putActivityOnTopOfHistoryStack:activity];
    }
    
    return activity;
}


// ---------------------------------------------------------------------------------------
// Puts the Activity on top of the history stack, making sure to keep the stack size bounded
//
-(void)putActivityOnTopOfHistoryStack:(MCActivity*)activity
{
    if ([MCViewManager sharedManager].stackSize == STACK_SIZE_DISABLED)
    {
        // don't save anything to the stack
        return;
    }else if ([MCViewManager sharedManager].stackSize != STACK_SIZE_UNLIMITED)
    {
        // bound the size
        NSAssert([MCViewManager sharedManager].stackSize > 0, @"stack size must be positive");
        
        if ([MCViewManager sharedManager].historyStack.count >= [MCViewManager sharedManager].stackSize  && [MCViewManager sharedManager].historyStack > 0)
        {
            [[MCViewManager sharedManager].historyStack removeObjectAtIndex:0]; // remove the first object to keep the stack size bounded
        }
    }
    
    // add the new object on the stack
    [[[MCViewManager sharedManager] historyStack] addObject:activity];
}


#pragma mark Push helpers

/**
 * We know which Activity we want to push.
 * We have to find it in the stack, remove it, add it on top
 *
 */
-(MCActivity *)pushActivityFromHistory:(MCActivity *)activity
{
    NSAssert([MCViewManager sharedManager].historyStack.count > 0, @"%s : something should be on the stack", __func__);
    BOOL found = false;
    
    // Try to find matching Activity in historyStack
    for (int i=0; i<[MCViewManager sharedManager].historyStack.count; i++)
    {
        if (activity == [[MCViewManager sharedManager].historyStack objectAtIndex:i])
        {
            [[MCViewManager sharedManager].historyStack removeObjectAtIndex:i];
            found = true;
            break;
        }
    }
    
    NSAssert(found, @"You tried to pushActivityFromHistory but provided Activity couldn't be found : %@", [activity description]);
    
    // We can put it on top
    [[MCViewManager sharedManager].historyStack addObject:activity];
    
    return activity;
}


/**
 * We know where is the Activity (by it's position in the stack)
 * We have to find it in the stack, remove it, add it on top.
 * @discussion number = 1 means last Activity
 *
 */
-(MCActivity *)pushActivityFromHistoryByNumber:(int)numberInHistory
{
#warning make sure NSAssert is good
    NSAssert([MCViewManager sharedManager].historyStack.count > numberInHistory, @"%s : something should be on the stack", __func__);
    
    // We first have to transform numberInHistory to position in stack -> (array count - numberInHistory - 1)
    int indexInStack = [MCViewManager sharedManager].historyStack.count - numberInHistory - 1;
    
    // Get the Activity, then delete it then put it on top
    MCActivity *foundActivity = [[MCViewManager sharedManager].historyStack objectAtIndex:indexInStack];
    [[MCViewManager sharedManager].historyStack removeObjectAtIndex:indexInStack];
    [[MCViewManager sharedManager].historyStack addObject:foundActivity];
    
    return foundActivity;
}

/**
 * We know the name of the ViewController, let's find the corresponding Activity
 * We have to find it in the stack, remove it, add it on top.
 *
 */
-(MCActivity *)pushActivityFromHistoryByName:(NSString *)viewName
{
    return nil;
}


#pragma mark Pop helpers


// ---------------------------------------------------------------------------------------
// Goes back in historyStack "popNum" times.
// Starting from 1, meaning back to previous Activity.
//
-(MCActivity*)popHistoryStack: (int) popNum
{
    NSAssert([MCViewManager sharedManager].historyStack.count > 0, @"something should be on the stack");
    
    MCActivity* retActivity = nil;
    for (int i =0; i <= popNum; i++)
    {
        if ([MCViewManager sharedManager].historyStack.count > 0 && i != popNum)
        {
            [[MCViewManager sharedManager].historyStack removeLastObject]; // this is the shown view, we don't want to stay on this view so discard it
            retActivity = [[MCViewManager sharedManager].historyStack lastObject];
        }
        else
        {
            return retActivity;
        }
    }
    return nil; // nothing on the history stack
}

-(MCActivity*)getHistoricalActivityAtIndex: (int) historyNum
{
    NSAssert([MCViewManager sharedManager].historyStack.count > historyNum, @"something should be on the stack");
    
    MCActivity* retActivity = nil;
    
    retActivity = [[MCViewManager sharedManager].historyStack objectAtIndex: historyNum];
    
    [[MCViewManager sharedManager].historyStack removeObjectAtIndex:historyNum];
    
    //  NSRange r;
    //  r.location = historyNum;
    //  r.length = [[MCViewManager sharedManager].historyStack count] - historyNum;
    //
    //  [[MCViewManager sharedManager].historyStack  removeObjectsInRange: r];
    
    return retActivity;
}


#pragma mark - View-Controllers related


-(MCViewController*) loadOrCreateViewController:(NSString*)sectionOrViewName
{
    // create global view cache if it doesn't already exist
    if (!_dictCacheView)
    {
        _dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    // test for existence
    MCViewController* vc = [_dictCacheView objectForKey:sectionOrViewName];
    if (vc == nil)
    {
        // create the view controller
        vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
        NSAssert(vc != nil, @"VC should exist");
        
        [vc onCreate];
        [_dictCacheView setObject:vc forKey:sectionOrViewName];
    }
    
    return vc;
    
}

-(MCViewController*) forceLoadViewController:(NSString*)sectionOrViewName
{
    // create global view cache if it doesn't already exist
    if (!_dictCacheView){
        _dictCacheView = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    // create the view controller
    MCViewController* vc = (MCViewController*) [[MCViewManager sharedManager] createViewController:sectionOrViewName];
    NSAssert(vc != nil, @"VC should exist");
    [vc onCreate];
    
    //
    [_dictCacheView setObject:vc forKey:sectionOrViewName];
    return vc;
}


// ----------------------------------------------------------------------------------------
// This method deals with switching the view during a transition
// Section may be the same, or may not.
// View may be the same, or may not
//
//
-(void)loadNewSection:(MCSectionViewController*)sectionVC andView:(MCViewController*)viewVC withActivity:(MCActivity*)activity
{
    
    // We get the wanted transition
    int transitionStyle = [activity transitionAnimationStyle];
    
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
    if (_currentSectionVC != sectionVC ){
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
            [self.view insertSubview:sectionVC.view belowSubview:_currentSectionVC.view];
        } else {
            [self.view addSubview:sectionVC.view];
        }
        
        // 1.4
        MCSectionViewController* oldSectionVC = _currentSectionVC;
        [oldSectionVC.currentViewVC resignFirstResponder];
        [oldSectionVC resignFirstResponder];
        
        // 1.5 : Returns True if our custom animation was applied.
        BOOL transitionApplied = [MCMainViewController applyTransitionFromView:oldSectionVC.view toView:sectionVC.view transition:transitionStyle completion:^{
            
            // 1.5.1
            if (oldSectionVC != _currentSectionVC)
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
                if (oldSectionVC != _currentSectionVC)
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
    _currentSectionVC = sectionVC;
    _currentSectionVC.currentViewVC = viewVC;
}




- (void)overlayButtonPressed:(id)sender
{
    NSMutableArray* newArray = [NSMutableArray arrayWithArray:_screenOverlaySlideshow];
    if (newArray.count > 0)
    {
        [newArray removeObjectAtIndex:0];
    }
    _screenOverlaySlideshow = newArray;
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
