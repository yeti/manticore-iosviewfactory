//
//  MCViewFactory.m
//  Manticore iOSViewManager
//
//  Created by Philippe Bertin on August 1, 2014
//  Copyright (c) 2014 Yeti LLC. All rights reserved.
//

#import "MCViewManager.h"
#import "MCMainViewController.h"
#import <QuartzCore/QuartzCore.h>


// ref. http://stackoverflow.com/questions/923706/checking-if-a-nib-or-xib-file-exists
#define AssertFileExists(path) NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot find the file: %@", path)
#define AssertNibExists(file_name_string) AssertFileExists([[NSBundle mainBundle] pathForResource:file_name_string ofType:@"nib"])



#pragma mark
#pragma mark - MCViewManager class

@interface MCViewManager ()


/*!
 * Error dictionary observed by MCMainViewController
 */
@property(nonatomic, strong) NSDictionary *errorDict;


/*!
 * Pointer to the current Activity, observed by MCMainViewController
 */
@property(atomic, strong) MCActivity *currentActivity;


/*!
 * Activities history stack
 */
@property(nonatomic, strong, readwrite) NSMutableArray *historyStack;

@end


@implementation MCViewManager


@synthesize screenOverlay;
@synthesize screenOverlays;


#pragma mark - Initialization

-(id)init{
    if (self = [super init]){
        _stackSize = 0;
        [self clearHistoryStack];
    }
    return self;
}


+(MCViewManager *)sharedManager
{
    static MCViewManager* sharedManager = nil;
	static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[MCViewManager alloc] init];
    });
    return sharedManager;
}


#pragma mark - View-Controllers related


-(UIViewController*)createViewController:(NSString*)sectionOrViewName
{
    // Get the class from string
    Class class = NSClassFromString(sectionOrViewName);
    
    // Assert the class exists and the nib file exists
    NSAssert(class != nil, @"You tried to instanciate a Class that does not exists : %@. Class must exist.", sectionOrViewName);
    
    // Assert the nib file exists
    AssertNibExists(sectionOrViewName);
    
    // Create the viewController
    UIViewController* vc = [[class alloc] initWithNibName:sectionOrViewName bundle:nil] ;
  
#ifdef DEBUG
    NSLog(@"Created a view controller %@", [vc description]);
#endif
    
  return vc;
}


/*!
 *
 * 1. We have to either find the activity of create it (and deal with historyStack)
 * 2. Populate the activity with new activityInfos from intent
 * 3. Set the activity as new current Activity
 *
 */
-(MCActivity *)processIntent: (MCIntent *)intent
{
    // 1.
    MCActivity *activity = [self loadOrCreateActivityWithIntent:intent];
    
    // 2.
    [activity.activityInfos setValuesForKeysWithDictionary:[intent activityInfos]];
    activity.transitionAnimationStyle = intent.transitionAnimationStyle;
    
    // 3.
    [self setCurrentActivity:activity];
    
    return activity;
}



#pragma mark -


- (void) clearHistoryStack
{
    _historyStack = [NSMutableArray arrayWithCapacity:_stackSize];
}


- (void) clearViewCache
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCMainViewController_flushViewCache" object:self];
}


#pragma mark -

-(void) setErrorTitle:(NSString*) title andDescription:(NSString*) description
{
    if (title == nil)
        title = @"";
    
    if (description == nil)
        description = @"";
    
    [self setErrorDict: [NSDictionary dictionaryWithObjects:@[title, description] forKeys:@[@"title", @"description"]]];
}

#pragma mark - Setters / Getters

-(void)setStackSize:(int)stackSize
{
    // Verify stackSize if >= 0
    NSAssert(stackSize >= 0, @"Stack size can not be less than 0, you tried to set it at %i", stackSize);
    _stackSize = stackSize;
    
    //TODO : if stackSize < currentStackSize remove from stack
}


#pragma mark - Load and create Activities

/*!
 *
 * This method will create a new Activity if intent was create with [MCIntent newActivity...] and therefore contains an associated section (and usually an associated view too) and no stackRequestDescriptor. 
 *
 * This method will load the activity from the stack if the intent contains a stackRequestDescriptor. It will try to find the Activity corresponding to the descriptor, deal with the stack and return this activity.
 *
 * Stack only has to be managed when an activity is created.
 *
 */
-(MCActivity *)loadOrCreateActivityWithIntent:(MCIntent *)intent
{
    MCActivity *activity = nil;
    
    if (intent.stackRequestDescriptor == nil && intent.sectionName)
    {
        activity = [self createActivityWithIntent:intent];
        [self addActivityOnTopOfStack:activity];
    }
    
    if (intent.stackRequestDescriptor != nil)
    {
        NSAssert((_stackSize != 1), @"Stack size can not but disabled (=1) when trying to pop or push");
        NSAssert((_historyStack.count > 1), @"Stack needs at least 2 Activies in stack (including current) when trying to pop or push");
        
        // See if push of pop method wanted and call appropriate method.
        if (intent.stackRequestDescriptor.requestType == POP)
        {
            activity = [self findAndPopToActivityOnStack:intent];
        }
        if (intent.stackRequestDescriptor.requestType == PUSH)
        {
            activity = [self findAndPushActivityOnTopOfStack:intent];
        }
    }
    
    return activity;
}

/*!
 * Intent to a new Activity. This method creates it, puts it on top of the stack and return it.
 * 
 * @param intent The intent containing information for creating a new Activity.
 * @return The newly created activity.
 *
 */
-(MCActivity *)createActivityWithIntent:(MCIntent *)intent
{
    MCActivity *activity = nil;
    
    // If intent does not have a viewName then instantiate a Section Activity
    if (!intent.viewName)
    {
        activity = [[MCActivity alloc] initWithAssociatedSectionNamed:intent.sectionName];
    }
    else{
        activity = [[MCActivity alloc] initWithAssociatedViewNamed:intent.viewName
                                                    inSectionNamed:intent.sectionName];
    }
    return activity;
}


/*!
 * Intent contains a stackRequestDescriptor with a Push type. This method will try to find the activity corresponding to the given descriptor, then push it on top of the stack.
 *
 * @param intent The intent containing information for finding the activity in the stack.
 * @return The found activity or nil if not found. It will create an assertion anyway.
 *
 */
-(MCActivity *)findAndPushActivityOnTopOfStack:(MCIntent *)intent
{
    // RequestInfo
    NSObject *info = intent.stackRequestDescriptor.requestInfos;
    
    // Position in stack = -1 : not found.
    NSInteger foundPositionInStack = -1;
    
    // As of this version, only pushing with criteria "history" is available
    NSAssert(intent.stackRequestDescriptor.requestCriteria == HISTORY, @"%s : MCError, put a ticket on GitHub. Can not find an Activity to push with criteria other than HISTORY", __func__);
    
    if (info == nil)
    {
        NSAssert(false, @"%s : MCError, put a ticket on GitHub. Can not find an Activity to push without requestInfo", __func__);
    }
    else
        if ([info isKindOfClass:[NSNumber class]])
        {
            foundPositionInStack = [self positionOfActivityInHistoryByPosition:(NSNumber*)info];
        }
    else
        if ([info isKindOfClass:[NSString class]])
        {
            foundPositionInStack = [self positionOfActivityInHistoryByName:(NSString*)info];
        }
    else
        if ([info isKindOfClass:[MCActivity class]])
        {
            foundPositionInStack = [self positionOfActivityInHistory:(MCActivity*)info];
        }
    
    NSAssert(foundPositionInStack != 0, @"%s : Can not push current intent", __func__, intent);
    NSAssert(foundPositionInStack > 0, @"%s : Could not find activity corresponding to intent : %@", __func__, intent);
    
    // Find and remove activity at position
    MCActivity *activity = [_historyStack objectAtIndex:foundPositionInStack];
    [_historyStack removeObjectAtIndex:foundPositionInStack];
    
    // Push on top of stack
    [_historyStack addObject:_historyStack];
    
    return activity;
}


/*!
 * Intent contains a stackRequestDescriptor with a Pop type. This method will try to find the activity corresponding to the given descriptor, then pop each Activities until this one.
 *
 * @param intent The intent containing information for finding the activity in the stack.
 * @return The found activity or nil if not found. It will create an assertion anyway.
 *
 */
-(MCActivity *)findAndPopToActivityOnStack:(MCIntent *)intent
{
    return nil;
}

#pragma mark Dealing with history stack when creating Activity

/*!
 * This method checks the stackSize and deal with adding/removing Activities from the stack if necessary.
 *
 * STACK_SIZE_DISABLED = 1 ; STACK_SIZE_UNLIMITED = 0 .
 *
 * @param activity Activity to put on top of the stack.
 *
 */
-(void)addActivityOnTopOfStack:(MCActivity *)activity
{
    // Stack disabled, no saving on stack : return
    if (_stackSize == STACK_SIZE_DISABLED)
        return;
    
    // Add activity on top of the stack
    [_historyStack addObject:activity];
    
    // Now check if adding the activity made historyStack too big
    if (_stackSize != STACK_SIZE_UNLIMITED)
    {
        NSAssert(_stackSize > 0, @"stack size must be positive");
        
        if (_historyStack.count > _stackSize)
        {
            // Remove first object to keet the stack bounded by stackSize.
            [_historyStack removeObjectAtIndex:0];
        }
    }
    

}


#pragma mark - Methods to find position in stack
// These methods do not depend on the fact that it is pushed/popped

#pragma mark In history

/*!
 * Position -1 = not found
 */
-(NSInteger)positionOfActivityInHistory:(MCActivity *)ptrToActivity
{
    for (NSInteger i=_historyStack.count-1; i>=0; i--)
    {
        if ([_historyStack objectAtIndex:i] == ptrToActivity)
            return i;
    }
    // Not found
    return -1;
}

/*!
 * Given poisition (positionFromLast) symmetrically at opposite position from center of historyStack.
 */
-(NSInteger)positionOfActivityInHistoryByPosition:(NSNumber *)positionFromLast
{
    NSInteger position = _historyStack.count - [positionFromLast integerValue] - 1;
    return position;
}

/*!
 * Check every viewName (then sectionName is no viewName) for given viewName.
 * Returns position of first occurence found
 */
-(NSInteger)positionOfActivityInHistoryByName:(NSString *)viewName
{
    for (NSInteger i=_historyStack.count-1; i>=0; i--)
    {
        MCActivity *activity = (MCActivity *)[_historyStack objectAtIndex:i];
        if (activity.associatedViewName)
        {
            if ([activity.associatedViewName isEqualToString:viewName])
                return i;
        } else
        {
            if ([activity.associatedSectionName isEqualToString:viewName])
                return i;
        }
        
    }
    // Not found
    return -1;
}

#pragma mark Root in Section


#pragma mark Last in Section


@end
