//
//  Copyright © 2017. Emarsys. All rights reserved.
//

#import "EMSNotificationService.h"
#import "EMSNotificationService+Actions.h"
#import "EMSNotificationService+PushToInApp.h"
#import "EMSNotificationService+Attachment.h"

typedef void(^ContentHandler)(UNNotificationContent *contentToDeliver);

@interface EMSNotificationService () <NSURLSessionDelegate>

@property(nonatomic, strong) ContentHandler contentHandler;
@property(nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation EMSNotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    _bestAttemptContent = (UNMutableNotificationContent *) [request.content mutableCopy];

    if (!self.bestAttemptContent) {
        contentHandler(request.content);
        return;
    }

    MEDownloader *downloadUtils = [MEDownloader new];

    dispatch_group_t dispatchGroup = dispatch_group_create();

    __weak typeof(self) weakSelf = self;
    dispatch_group_enter(dispatchGroup);
    [self createCategoryForContent:self.bestAttemptContent
                 completionHandler:^(UNNotificationCategory *category) {
                     if (category) {
                         [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
                             [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[categories setByAddingObjectsFromArray:@[category]]];
                             weakSelf.bestAttemptContent.categoryIdentifier = category.identifier;
                             dispatch_group_leave(dispatchGroup);
                         }];
                     } else {
                         dispatch_group_leave(dispatchGroup);
                     }
                 }];

    dispatch_group_enter(dispatchGroup);
    [self createUserInfoWithInAppForContent:self.bestAttemptContent
                             withDownloader:downloadUtils
                          completionHandler:^(NSDictionary *extendedUserInfo) {
                              if (extendedUserInfo) {
                                  weakSelf.bestAttemptContent.userInfo = extendedUserInfo;
                              }
                              dispatch_group_leave(dispatchGroup);
                          }];

    dispatch_group_enter(dispatchGroup);
    [self createAttachmentForContent:self.bestAttemptContent
                      withDownloader:downloadUtils
                   completionHandler:^(NSArray<UNNotificationAttachment *> *attachments) {
                       weakSelf.bestAttemptContent.attachments = attachments;
                       dispatch_group_leave(dispatchGroup);
                   }];

    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
    contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

@end
