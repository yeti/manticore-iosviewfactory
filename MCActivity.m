/*
 MCActivity.m
 Manticore iOSViewFactory
 
 Created by Richard Fung on 9/19/12.
 Reworked, refactored and commented by Philippe Bertin on August 1, 2014
 
 Copyright (c) 2014 Yeti LLC. All rights reserved.

 */

#import "MCActivity.h"

// Activity properties
#define kSectionName    @"__SectionName__"
#define kViewName       @"__ViewName__"
#define kAnimationStlye @"__AnimationStyle__"


/*
 * A dynamic activity contains all the information for finding an Activity in the history stack.
 * These information are stored in a dictionary found in activityInfos for key : kDynamicActivity
 *
 */
#define kDynamicActivity @"__DynamicActivity__"
/*
 * This dictionary contains :
 *
 * "activityType"
 *      - "pop"     : when found, activity will be popped
 *      - "push"    : when found, activity will be pushed
 *
 * "searchCriteria"
 *      - "history" : History means looking at the stack as a whole.
 *      - "root"    : Root means the activity looked for is the root activity of a Section.
 *      - "last"    : Last means looking for the last activity that appeared in a given section.
 *
 * "userInfo" :
 *      - (MCActivity*) : a pointer to the wanted activity
 *      - (NSString *)  : a string representing the Activity's associated View name
 *      - (NSNumber*)   : an int representing a position in the stack
 *
 */


@interface MCActivity ()

@property (strong, nonatomic, readwrite) NSMutableDictionary   *activityInfos;

@end



@implementation MCActivity


#pragma mark - Class methods


#pragma mark Section without view


+(MCActivity *) newActivityWithAssociatedSectionNamed: (NSString*)sectionName
{
    MCActivity* newActivity = [[MCActivity alloc] initWithAssociatedSectionNamed:sectionName];
    return newActivity;
}

+(MCActivity *) newActivityWithAssociatedSectionNamed: (NSString*)sectionName
                                         andAnimation:(UIViewAnimationOptions)animation
{
    MCActivity* newActivity = [[MCActivity alloc] initWithAssociatedSectionNamed:sectionName];
    [newActivity setTransitionAnimationStyle:animation];
    return newActivity;
}

+(MCActivity *) newActivityWithAssociatedSectionNamed:(NSString*)sectionName
                                     andActivityInfos:(NSMutableDictionary*)activityInfos
{
    MCActivity* newActivity = [[MCActivity alloc] initWithAssociatedSectionNamed:sectionName
                                                          andActivityInfos:activityInfos];
    return newActivity;
}


#pragma mark Section with view

+(MCActivity *) newActivityWithAssociatedViewNamed:(NSString*)viewName
                                    inSectionNamed:(NSString*)sectionName
{
    MCActivity* newActivity = [[MCActivity alloc] initWithAssociatedViewNamed:viewName
                                                         inSectionNamed:sectionName];
    return newActivity;
}

+(MCActivity *) newActivityWithAssociatedViewNamed:(NSString*)viewName
                                    inSectionNamed:(NSString*)sectionName
                                      andAnimation:(UIViewAnimationOptions)animation
{
    MCActivity* newActivity = [[MCActivity alloc] initWithAssociatedViewNamed:viewName
                                                         inSectionNamed:sectionName];
    [newActivity setTransitionAnimationStyle:animation];
    return newActivity;
}

#pragma mark To be removed

+(id) intentPreviousIntent
{
    return [MCActivity newActivityWithAssociatedSectionNamed:SECTION_LAST];
}

+(id) intentPreviousIntentWithAnimation:(UIViewAnimationOptions)animation
{
    return [MCActivity newActivityWithAssociatedSectionNamed:SECTION_LAST andAnimation:animation];
}

+(id) intentToLoadHistoricalIntentNumber: (NSNumber *) historyNum
{
    MCActivity *intent = [MCActivity newActivityWithAssociatedSectionNamed: SECTION_HISTORICAL];
    [intent.activityInfos setObject: historyNum forKey: @"historyNumber"];
    return intent;
}


#pragma mark Dynamic Push Activities

+(MCActivity *) pushActivityFromHistory: (MCActivity *) ptrToActivity
{
    NSAssert(ptrToActivity != nil, @"%s : given pointer to activity is nil", __func__);
    
    MCActivity* newActivity = [[MCActivity alloc] initDynamicActivityType:@"push"
                                                           searchCriteria:@"history"
                                                                 userInfo:ptrToActivity];
    return newActivity;
}


+(MCActivity *)pushActivityFromHistoryByPosition:(int)positionInStack
{
    NSAssert((positionInStack > 0), @"%s : positionInStack can not be %i", __func__, positionInStack);
    
    NSNumber *numberPosition = [NSNumber numberWithInt:positionInStack];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"push"
                                                           searchCriteria:@"history"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)pushActivityFromHistoryByName:(NSString *)mcViewControllerName
{
    NSAssert(NSClassFromString(mcViewControllerName), @"%s : %@ does not exist.", __func__, mcViewControllerName);
    
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"push"
                                                           searchCriteria:@"history"
                                                                 userInfo:mcViewControllerName];
    return newActivity;
}


#pragma mark Dynamic Pop Activities in history

+(MCActivity *)popToActivityInHistory:(MCActivity *)ptrToActivity
{
    NSAssert(ptrToActivity != nil, @"%s : given pointer to activity is nil", __func__);
    
    MCActivity* newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"history"
                                                                 userInfo:ptrToActivity];
    return newActivity;
}

+(MCActivity *)popToActivityInHistoryByPosition:(int)positionInStack
{
    NSAssert((positionInStack > 0), @"%s : positionInStack can not be %i", __func__, positionInStack);
    
    NSNumber *numberPosition = [NSNumber numberWithInt:positionInStack];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"history"
                                                                 userInfo:numberPosition];
    return newActivity;

}

+(MCActivity *)popToActivityInHistoryByPositionLast
{
    NSNumber *numberPosition = [NSNumber numberWithInt:1];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"history"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)popToActivityInHistoryByName:(NSString *)mcViewControllerName
{
    NSAssert(NSClassFromString(mcViewControllerName), @"%s : %@ does not exist.", __func__, mcViewControllerName);
    
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"history"
                                                                 userInfo:mcViewControllerName];
    return newActivity;
}


#pragma mark Dynamic Pop Activities to Section root

// popToActivityRoot is special as the number can not be known.
// Therefore, it is assigned number : -1.
//
+(MCActivity *)popToActivityRoot
{
    NSNumber *numberPosition = [NSNumber numberWithInt:1];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"root"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)popToActivityRootInSectionCurrent
{
    NSNumber *numberPosition = [NSNumber numberWithInt:0];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"root"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)popToActivityRootInSectionLast
{
    NSNumber *numberPosition = [NSNumber numberWithInt:1];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"root"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)popToActivityRootInSectionNamed:(NSString *)mcSectionViewControllerName
{
    NSAssert(NSClassFromString(mcSectionViewControllerName), @"%s : %@ does not exist.", __func__, mcSectionViewControllerName);
    
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"root"
                                                                 userInfo:mcSectionViewControllerName];
    return newActivity;
}


#pragma mark Dynamic Pop Activities to Section last

+(MCActivity *)popToActivityLastInSectionLast
{
    NSNumber *numberPosition = [NSNumber numberWithInt:0];
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"last"
                                                                 userInfo:numberPosition];
    return newActivity;
}

+(MCActivity *)popToActivityLastInSectionNamed:(NSString *)mcSectionViewControllerName
{
    NSAssert(NSClassFromString(mcSectionViewControllerName), @"%s : %@ does not exist.", __func__, mcSectionViewControllerName);
    
    MCActivity *newActivity = [[MCActivity alloc] initDynamicActivityType:@"pop"
                                                           searchCriteria:@"last"
                                                                 userInfo:mcSectionViewControllerName];
    return newActivity;
}


#pragma mark - Private initialization methods

-(id) initWithAssociatedSectionNamed: (NSString*)sectionName
{
    // Comment off when finished updating methods
    //NSAssert(NSClassFromString(sectionName), @"%s : Section %@ could not be found", __func__, sectionName);
    
    if (self = [super init])
    {
        _activityInfos = [NSMutableDictionary dictionaryWithCapacity:4];
        [_activityInfos setObject:sectionName forKey:kSectionName];
    }
    return self;
}

-(id) initWithAssociatedViewNamed: (NSString*)viewName
                   inSectionNamed:(NSString*)sectionName
{
    NSAssert(NSClassFromString(viewName), @"%s : View %@ could not be found", __func__, viewName);
    NSAssert(NSClassFromString(sectionName), @"%s : Section %@ could not be found", __func__, sectionName);
    
    if (self = [super init])
    {
        _activityInfos = [NSMutableDictionary dictionaryWithCapacity:4];
        [_activityInfos setObject:sectionName forKey:kSectionName];
        [_activityInfos setObject:viewName forKey:kViewName];
        
    }
    return self;
}

-(id) initWithAssociatedSectionNamed: (NSString*)sectionName
                    andActivityInfos:(NSMutableDictionary*)activityInfos
{
    NSAssert(NSClassFromString(sectionName), @"%s : Section %@ could not be found", __func__, sectionName);
    
    if (self = [super init])
    {
        _activityInfos = [NSMutableDictionary dictionaryWithDictionary:activityInfos];
        [_activityInfos setObject:sectionName forKey:kSectionName];
    }
    
    return self;
}

/*!
 * Initialize a Dynamic Activity : an activity that contains all the information for finding an Activity in the history stack.
 *
 * @param activityType      Either "pop" or "push". These are the two supported types by Manticore. When found, the Activity will either be pushed or popped on top of the stack.
 * @param searchCriteria    Can be "history", "root" or "last". History means looking at the stack as a whole. Root means the activity looked for is the root activity of a Section. Last means looking for the last activity that appeared in a given section.
 * @param userInfo          Currently supported userInfo types are : (MCActivity*), (NSString *), and ints represented by (NSNumber*).
 *
 */
-(id) initDynamicActivityType:(NSString *)dynamicActivityType
               searchCriteria:(NSString *)searchCriteria
                     userInfo:(id)userInfo
{
    if (self = [super init])
    {
        _activityInfos = [NSMutableDictionary dictionaryWithCapacity:4];
        NSDictionary *dynamicInfos = @{@"dynamicActivityType": dynamicActivityType,
                                       @"searchCriteria" : searchCriteria,
                                       @"userInfo" : userInfo};
        [_activityInfos setObject:dynamicInfos forKey:kDynamicActivity];
    }
    
    return self;
}

#pragma mark - Getters & Setters

-(NSString*) associatedSectionName
{
    NSAssert(_activityInfos, @"MCActivity %@ does not have a activityInfos Dictionary", self);
    return [_activityInfos objectForKey:kSectionName];
}

-(NSString*) associatedViewName
{
    NSAssert(_activityInfos, @"MCActivity %@ does not have a activityInfos Dictionary", self);
    return [_activityInfos objectForKey:kViewName];
}

-(NSMutableDictionary*) activityInfos
{
    NSAssert(_activityInfos, @"MCActivity %@ does not have a activityInfos Dictionary", self);
    return _activityInfos;
}


-(UIViewAnimationOptions)transitionAnimationStyle
{
    NSAssert(_activityInfos, @"MCActivity %@ does not have a activityInfos Dictionary", self);
    
    if ([_activityInfos objectForKey:kAnimationStlye])
    {
        return [[_activityInfos objectForKey:kAnimationStlye] intValue];
    }
    else
    {
        return UIViewAnimationOptionTransitionNone;
    }
}

-(void) setTransitionAnimationStyle: (UIViewAnimationOptions) animationStyle
{
    [_activityInfos setObject:[NSNumber numberWithInt:animationStyle] forKey:kAnimationStlye];
}

-(NSString *) description {
    return [NSString stringWithFormat:@"MCActivity section=%@, view=%@, dictionary=%@", self.associatedSectionName, self.associatedViewName, self.activityInfos];
}

@end
