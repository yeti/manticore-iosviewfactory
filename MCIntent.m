/*
 MCIntent.m
 Manticore iOSViewFactory
 
 Created by Richard Fung on 9/19/12.
 Reworked, refactored and commented by Philippe Bertin on August 1, 2014
 
 Copyright (c) 2014 Yeti LLC. All rights reserved.

 */

#import "MCIntent.h"

#define kSectionName    @"__SectionName__"
#define kViewName       @"__ViewName__"
#define kAnimationStlye @"__AnimationStyle__"
#define kSearchInfos    @"__SearchInfos__"
#define kType           @"__Type__"


@interface MCIntent ()

@property (strong, nonatomic, readwrite) NSMutableDictionary   *savedInstanceState;

@end



@implementation MCIntent


#pragma mark - Class methods


#pragma mark Section without view


+(id) intentWithSectionName: (NSString*)sectionName
{
    MCIntent* newIntent = [[MCIntent alloc] initWithSectionName:sectionName];
    return newIntent;
}

+(id) intentWithSectionName: (NSString*)sectionName andAnimation:(UIViewAnimationOptions)animation
{
    MCIntent* newIntent = [[MCIntent alloc] initWithSectionName:sectionName];
    [newIntent setAnimationStyle:animation];
    return newIntent;
}

+(id) intentWithSectionName:(NSString*)sectionName andSavedInstance:(NSMutableDictionary*)savedInstanceState
{
    MCIntent* newIntent = [[MCIntent alloc] initWithSectionName:sectionName andSavedInstance:savedInstanceState];
    return newIntent;
}


#pragma mark Section with view

+(id) intentWithSectionName:(NSString*)sectionName andViewName:(NSString*)viewName
{
  MCIntent* newIntent = [[MCIntent alloc] initWithSectionName:sectionName viewName:viewName];
  return newIntent;
}

+(id) intentWithSectionName:(NSString*)sectionName viewName:(NSString*)viewName andAnimation:(UIViewAnimationOptions)animation
{
    MCIntent* newIntent = [[MCIntent alloc] initWithSectionName:sectionName viewName:viewName];
    [newIntent setAnimationStyle:animation];
    return newIntent;
}

#pragma mark To be removed

+(id) intentPreviousIntent
{
    return [MCIntent intentWithSectionName:SECTION_LAST];
}

+(id) intentPreviousIntentWithAnimation:(UIViewAnimationOptions)animation
{
    return [MCIntent intentWithSectionName:SECTION_LAST andAnimation:animation];
}

+(id) intentToLoadHistoricalIntentNumber: (NSNumber *) historyNum
{
    MCIntent *intent = [MCIntent intentWithSectionName: SECTION_HISTORICAL];
    [intent.savedInstanceState setObject: historyNum forKey: @"historyNumber"];
    return intent;
}


#pragma mark Dynamic Push intents

+(MCIntent *) pushIntentFromHistory: (MCIntent *) ptrToIntent
{
    
}


+(MCIntent *)pushIntentFromHistoryByPosition:(int)positionInStack
{
    
}

+(MCIntent *)pushIntentFromHistoryByName:(NSString *)mcViewControllerName
{
    
}


#pragma mark Dynamic Pop intents in history

+(MCIntent *)popToIntentInHistory:(MCIntent *)ptrToIntent
{
    
}

+(MCIntent *)popToIntentInHistoryByPosition:(int)positionInStack
{
    
}

+(MCIntent *)popToIntentInHistoryByPositionLast
{
    
}

+(MCIntent *)popToIntentInHistoryByName:(NSString *)mcViewControllerName
{
    
}


#pragma mark Dynamic Pop intents to Section root

+(MCIntent *)popToIntentRoot
{
    
}

+(MCIntent *)popToIntentRootInSectionCurrent
{
    
}

+(MCIntent *)popToIntentRootInSectionLast
{
    
}

+(MCIntent *)popToIntentRootInSectionNamed:(NSString *)mcSectionViewControllerName
{
    
}


#pragma mark Dynamic Pop intents to Section last

+(MCIntent *)popToIntentLastInSectionLast
{
    
}

+(MCIntent *)popToIntentLastInSectionNamed:(NSString *)mcSectionViewControllerName
{
    
}


#pragma mark - Private initialization methods

-(id) initWithSectionName: (NSString*)name
{
    if (self = [super init])
    {
        _savedInstanceState = [NSMutableDictionary dictionaryWithCapacity:4];
        [_savedInstanceState setObject:name forKey:kSectionName];
    }
    return self;
}

-(id) initWithSectionName: (NSString*)name viewName:(NSString*)viewName 
{
  if (self = [super init])
  {
    _savedInstanceState = [NSMutableDictionary dictionaryWithCapacity:4];
    [_savedInstanceState setObject:name forKey:kSectionName];
    [_savedInstanceState setObject:viewName forKey:kViewName];
    
  }
  return self;
}

-(id) initWithSectionName: (NSString*)name andSavedInstance:(NSMutableDictionary*)savedInstanceState
{
    if (self = [super init])
    {
        _savedInstanceState = [NSMutableDictionary dictionaryWithDictionary:savedInstanceState];
        [_savedInstanceState setObject:name forKey:kSectionName];
    }
  
    return self;
}

#pragma mark - Getters & Setters

-(NSString*) sectionName
{
    NSAssert([_savedInstanceState objectForKey:kSectionName], @"MCIntent %@ does not have a section name", self);
    return [_savedInstanceState objectForKey:kSectionName];
}

-(NSString*) viewName
{
    NSAssert(_savedInstanceState, @"MCIntent %@ does not have a savedInstanceState Dictionary", self);
    return [_savedInstanceState objectForKey:kViewName];
}

-(NSMutableDictionary*) savedInstanceState
{
    NSAssert(_savedInstanceState, @"MCIntent %@ does not have a savedInstanceState Dictionary", self);
    return _savedInstanceState;
}


-(UIViewAnimationOptions)animationStyle
{
    NSAssert(_savedInstanceState, @"MCIntent %@ does not have a savedInstanceState Dictionary", self);
    
    if ([_savedInstanceState objectForKey:kAnimationStlye])
    {
        return [[_savedInstanceState objectForKey:kAnimationStlye] intValue];
    }
    else
    {
        return UIViewAnimationOptionTransitionNone;
    }
}

-(void) setAnimationStyle: (UIViewAnimationOptions) animationStyle
{
    [_savedInstanceState setObject:[NSNumber numberWithInt:animationStyle] forKey:kAnimationStlye];
}

-(NSString *) description {
    return [NSString stringWithFormat:@"MCIntent section=%@, view=%@, dictionary=%@", self.sectionName, self.viewName, self.savedInstanceState];
}

@end
