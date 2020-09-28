/*
 *  MPEdn: An EDN (extensible data notation) I/O library for OS X and
 *  iOS. See https://github.com/scramjet/mpedn and
 *  https://github.com/edn-format/edn.
 *
 *  Copyright (c) 2013 Matthew Phillips <m@mattp.name>
 *
 *  The use and distribution terms for this software are covered by
 *  the Eclipse Public License 1.0
 *  (http://opensource.org/licenses/eclipse-1.0.php). By using this
 *  software in any fashion, you are agreeing to be bound by the terms
 *  of this license.
 *
 *  You must not remove this notice, or any other, from this software.
 */

#import "MPEdnDateCodec.h"
#import "MPEdnWriter.h"
#import "MPEdnParser.h"

static NSDateFormatter *dateFormatterTimezone;
static NSDateFormatter *dateFormatterIso8601;
static NSDateFormatter *dateFormatterClojure;

@implementation MPEdnDateCodec

+ (void) initialize
{
  if (self == [MPEdnDateCodec class])
  {
    // NSDateFormatter is *very* slow to create, pre-allocate one
    // NB NSDateFormatter is thread safe only in iOS 7+ and OS X 10.9+
    // TODO warn if being compiled on a platform where this is unsafe
    dateFormatterTimezone = [NSDateFormatter new];
    dateFormatterIso8601 = [NSDateFormatter new];
    dateFormatterClojure = [NSDateFormatter new];

    // Support parsing dates with timezone information
    dateFormatterTimezone.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
    dateFormatterTimezone.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatterTimezone.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    // Support parsing dates optionally ending with 'Z'
    dateFormatterIso8601.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatterIso8601.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatterIso8601.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    // NB: hardcoding "-00:00" (UTC) as timezone for writing
    dateFormatterClojure.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'-00:00'";
    dateFormatterClojure.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatterClojure.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  }
}

- (id) copyWithZone: (NSZone *) zone
{
  return [MPEdnDateCodec new];
}

- (NSString *) tagName
{
  return @"inst";
}

- (BOOL) canWrite: (id) value
{
  return [value isKindOfClass: [NSDate class]];
}

- (void) writeValue: (id) value toWriter: (MPEdnWriter *) writer
{
  [writer outputObject: [dateFormatterClojure stringFromDate: value]];
}

- (id) readValue: (id) value
{
  if ([value isKindOfClass: [NSString class]])
  {
    // Try the timezone date formatter first (which is more likely to parse successfully)
    NSDate *date = [dateFormatterTimezone dateFromString: value];
      
    if (!date)
    {
      // If unsuccessful, try the ISO 8601 formatter
      date = [dateFormatterIso8601 dateFromString: value];
    }

    if (date)
    {
      return date;
    } else
    {
      return [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
              userInfo: @{NSLocalizedDescriptionKey :
                          [NSString stringWithFormat: @"Bad RFC 3339 date: %@", value]}];
    }
  } else
  {
    return [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
              userInfo: @{NSLocalizedDescriptionKey : @"Expected a string for an inst-tagged date value"}];
  }
}

@end
