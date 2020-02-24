//
// Copyright (c) 2018 Emarsys. All rights reserved.
//
#import "NSDate+EMSCore.h"

@implementation NSDate (EMSCore)

- (NSNumber *)numberValueInMillis {
    return [self timeIntervalInMillis:self.timeIntervalSince1970];
}

- (NSNumber *)numberValueInMillisFromDate:(NSDate *)date {
    return [self timeIntervalInMillis:[self timeIntervalSinceDate:date]];
}

- (NSString *)stringValueInUTC {
    return [[NSDate utcDateFormatter] stringFromDate:self];
}


- (NSNumber *)timeIntervalInMillis:(NSTimeInterval)timeInterval {
    return @((long long) (timeInterval * 1000));
}

+ (NSDateFormatter *)utcDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
        
#warning Danny: Emarsys official SDK has a bug here: not setting locale, causing time string can be in 12hour format
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        
    });
    return dateFormatter;
}

@end
