#import "Kiwi.h"
#import "FakeStatusDelegate.h"
#import "MobileEngage.h"
#import "EMSConfigBuilder.h"
#import "EMSConfig.h"
#import "MEExperimental.h"
#import "MEExperimental+Test.h"
#import "MERequestContext.h"

#define DB_PATH [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"EMSSQLiteQueueDB.db"]

SPEC_BEGIN(IntegrationTests)

        __block EMSConfig *config;

        FakeStatusDelegate *(^createStatusDelegate)() = ^FakeStatusDelegate *() {
            FakeStatusDelegate *statusDelegate = [FakeStatusDelegate new];
            statusDelegate.printErrors = YES;
            return statusDelegate;
        };

        beforeEach(^{
            [MEExperimental enableFeature:INAPP_MESSAGING];
            [[NSFileManager defaultManager] removeItemAtPath:DB_PATH
                                                       error:nil];

            NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSuiteName];
            [userDefaults removeObjectForKey:kMEID];
            [userDefaults removeObjectForKey:kMEID_SIGNATURE];
            [userDefaults removeObjectForKey:kLastAppLoginPayload];
            [userDefaults synchronize];

            userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.emarsys.core"];
            [userDefaults setObject:@"IntegrationTests" forKey:@"kHardwareIdKey"];

            config = [EMSConfig makeWithBuilder:^(EMSConfigBuilder *builder) {
                [builder setCredentialsWithApplicationCode:@"14C19-A121F"
                                       applicationPassword:@"PaNkfOD90AVpYimMBuZopCpm8OWCrREu"];
                [builder setMerchantId:@"dummyMerchantId"];
                [builder setContactFieldId:@3];
            }];
        });

        describe(@"Public interface methods", ^{
            it(@"should return with eventId, and finish with success for anonymousAppLogin", ^{
                [MobileEngage setupWithConfig:config
                                launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage appLogin];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });

            it(@"should return with eventId, and finish with success for appLogin", ^{
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage appLoginWithContactFieldId:@3
                        contactFieldValue:@"test@test.com"];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });

            it(@"should return with eventId, and finish with success for trackMessageOpen:", ^{
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage trackMessageOpenWithUserInfo:@{@"u": @"{\"sid\":\"dd8_zXfDdndBNEQi\"}"}];

                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });

            it(@"should return with eventId, and finish with success for trackCustomEvent without attributes", ^{
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                [MobileEngage appLogin];
                [statusDelegate waitForNextSuccess];

                NSString *eventId = [MobileEngage trackCustomEvent:@"eventName"
                        eventAttributes:nil];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@2];
            });

            it(@"should return with eventId, and finish with success for trackCustomEvent with attributes", ^{
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                [MobileEngage appLogin];
                [statusDelegate waitForNextSuccess];

                NSString *eventId = [MobileEngage trackCustomEvent:@"eventName"
                        eventAttributes:@{
                                @"animal": @"cat",
                                @"drink": @"palinka",
                                @"food": @"pizza"
                        }];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@2];
            });

            it(@"should return with eventId, and finish with success for trackCustomEvent without attributes", ^{
                [MEExperimental reset];
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage trackCustomEvent:@"eventName"
                        eventAttributes:nil];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });

            it(@"should return with eventId, and finish with success for trackCustomEvent with attributes", ^{
                [MEExperimental reset];
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage trackCustomEvent:@"eventName"
                        eventAttributes:@{
                                @"animal": @"cat",
                                @"drink": @"palinka",
                                @"food": @"pizza"
                        }];
                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });

            it(@"should return with eventId, and finish with success for appLogout", ^{
                [MobileEngage setupWithConfig:config
                        launchOptions:[NSDictionary new]];
                FakeStatusDelegate *statusDelegate = createStatusDelegate();
                [MobileEngage setStatusDelegate:statusDelegate];

                NSString *eventId = [MobileEngage appLogout];

                [statusDelegate waitForNextSuccess];

                [[eventId shouldNot] beNil];
                [[statusDelegate.errors should] equal:@[]];
                [[@(statusDelegate.errorCount) should] equal:@0];
                [[@(statusDelegate.successCount) should] equal:@1];
            });
        });

SPEC_END
