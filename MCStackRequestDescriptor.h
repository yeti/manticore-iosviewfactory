//
//  MCStackRequestDescriptor.h
//  Pods
//
//  Created by Philippe Bertin on 8/7/14.
//
//

#import <Foundation/Foundation.h>

@interface MCStackRequestDescriptor : NSObject

/*
 *
 * "requestType"
 *      - "pop"     : when found, activity will be popped
 *      - "push"    : when found, activity will be pushed
 *
 * "requestCriteria"
 *      - "history" : History means looking at the stack as a whole.
 *      - "root"    : Root means the activity looked for is the root activity of a Section.
 *      - "last"    : Last means looking for the last activity that appeared in a given section.
 *
 * "requestInfo" :
 *      - (MCActivity*) : a pointer to the wanted activity
 *      - (NSString *)  : a string representing the Activity's associated View name
 *      - (NSNumber*)   : an int representing a position in the stack
 *
 */



@property (strong, nonatomic, readonly) NSString *requestType;
@property (strong, nonatomic, readonly) NSString *requestCriteria;
@property (strong, nonatomic, readonly) NSObject *requestInfos;


-(id)initWithRequestType:(NSString *)requestType
         requestCriteria:(NSString*)requestCriteria
             requestInfo:(NSObject*)requestInfo;

@end
