//
// Copyright (c) 2019 Emarsys. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "EMSPushV3Internal.h"
#import "EMSRequestFactory.h"
#import "EMSRequestManager.h"
#import "NSData+MobileEngine.h"
#import "NSDictionary+MobileEngage.h"
#import "NSError+EMSCore.h"
#import "EMSNotificationCache.h"
#import "EMSTimestampProvider.h"
#import "EMSActionFactory.h"
#import "EMSActionProtocol.h"

@interface EMSPushV3Internal ()

@property(nonatomic, strong) EMSRequestFactory *requestFactory;
@property(nonatomic, strong) EMSRequestManager *requestManager;
@property(nonatomic, strong) EMSNotificationCache *notificationCache;
@property(nonatomic, strong) EMSTimestampProvider *timestampProvider;
@property(nonatomic, strong) EMSActionFactory *actionFactory;

@end

@implementation EMSPushV3Internal

@synthesize silentMessageEventHandler = _silentMessageEventHandler;

- (instancetype)initWithRequestFactory:(EMSRequestFactory *)requestFactory
                        requestManager:(EMSRequestManager *)requestManager
                     notificationCache:(EMSNotificationCache *)notificationCache
                     timestampProvider:(EMSTimestampProvider *)timestampProvider
                         actionFactory:(EMSActionFactory *)actionFactory {
    NSParameterAssert(requestFactory);
    NSParameterAssert(requestManager);
    NSParameterAssert(notificationCache);
    NSParameterAssert(timestampProvider);
    NSParameterAssert(actionFactory);
    if (self = [super init]) {
        _requestFactory = requestFactory;
        _requestManager = requestManager;
        _notificationCache = notificationCache;
        _timestampProvider = timestampProvider;
        _actionFactory = actionFactory;
    }
    return self;
}

- (void)setPushToken:(NSData *)pushToken {
    [self setPushToken:pushToken
       completionBlock:nil];
}

- (void)setPushToken:(NSData *)pushToken
     completionBlock:(EMSCompletionBlock)completionBlock {
    _deviceToken = pushToken;
    NSString *deviceToken = [self.deviceToken deviceTokenString];
    EMSRequestModel *requestModel;
    if (deviceToken && [deviceToken length] > 0) {
        requestModel = [self.requestFactory createPushTokenRequestModelWithPushToken:deviceToken];
        [self.requestManager submitRequestModel:requestModel
                            withCompletionBlock:completionBlock];
    }
}

- (void)clearPushToken {
    [self clearPushTokenWithCompletionBlock:nil];
}

- (void)clearPushTokenWithCompletionBlock:(EMSCompletionBlock)completionBlock {
    _deviceToken = nil;
    EMSRequestModel *requestModel = [self.requestFactory createClearPushTokenRequestModel];
    [self.requestManager submitRequestModel:requestModel
                        withCompletionBlock:completionBlock];
}

- (void)trackMessageOpenWithUserInfo:(NSDictionary *)userInfo {
    [self trackMessageOpenWithUserInfo:userInfo
                       completionBlock:nil];
}

- (void)trackMessageOpenWithUserInfo:(NSDictionary *)userInfo
                     completionBlock:(EMSCompletionBlock)completionBlock {
    NSParameterAssert(userInfo);
    NSNumber *inbox = userInfo[@"inbox"];
    if (inbox && [inbox boolValue]) {
        [self.notificationCache cache:[[EMSNotification alloc] initWithUserInfo:userInfo
                                                              timestampProvider:self.timestampProvider]];
    }

    NSString *sid = [userInfo messageId];
    if (sid) {
        EMSRequestModel *requestModel = [self.requestFactory createEventRequestModelWithEventName:@"push:click"
                                                                                  eventAttributes:@{
                                                                                          @"origin": @"main",
                                                                                          @"sid": sid
                                                                                  }
                                                                                        eventType:EventTypeInternal];
        [self.requestManager submitRequestModel:requestModel
                            withCompletionBlock:completionBlock];

    } else if (completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock([NSError errorWithCode:1400
                              localizedDescription:@"No messageId found!"]);
        });
    }
}

- (void)handleMessageWithUserInfo:(NSDictionary *)userInfo {
    NSArray<NSDictionary *> *actions = userInfo[@"ems"][@"actions"];
    [self.actionFactory setEventHandler:self.silentMessageEventHandler];
    for (NSDictionary *actionDict in actions) {
        id<EMSActionProtocol> action = [self.actionFactory createActionWithActionDictionary:actionDict];
        [action execute];
    }
}

@end