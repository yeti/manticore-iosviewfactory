//
//  MCStackRequestDescriptor.m
//  Pods
//
//  Created by Philippe Bertin on 8/7/14.
//
//

#import "MCStackRequestDescriptor.h"


@interface MCStackRequestDescriptor ()

@property (strong, nonatomic, readwrite) NSString *requestType;
@property (strong, nonatomic, readwrite) NSString *requestCriteria;
@property (strong, nonatomic, readwrite) NSObject *requestInfos;

@end

@implementation MCStackRequestDescriptor

-(id)initWithRequestType:(NSString *)requestType
         requestCriteria:(NSString *)requestCriteria
             requestInfo:(NSObject *)requestInfo
{
    if (self = [super init])
    {
        _requestType = requestType;
        _requestCriteria = requestCriteria;
        _requestInfos = requestInfo;
        
        [self verifyEntries];
    }
    return self;
}

-(void)verifyEntries
{
    // Test for pop/push
    NSAssert(([_requestType isEqualToString:@"pop"]||[_requestType isEqualToString:@"push"]), @"%s : MCIntent can only create pop or push request. %@ is not supported yet.", __func__, _requestType);
    
    //Test for history/root/last
    NSAssert(([_requestCriteria isEqualToString:@"history"]||[_requestCriteria isEqualToString:@"root"]||[_requestCriteria isEqualToString:@"last"]), @"%s : MCIntent can only create history, root or last request criterias. %@ is not supported yet.", __func__, _requestCriteria);
    
    //Test for UserInfo
    //TODO
}

@end
