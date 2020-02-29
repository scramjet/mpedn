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

static NSDateFormatter *dateFormatter;

@implementation MPEdnDateCodec

+ (void) initialize
{
  if (self == [MPEdnDateCodec class])
  {
    // NSDateFormatter is *very* slow to create, pre-allocate one
    // NB NSDateFormatter is thread safe only in iOS 7+ and OS X 10.9+
    // TODO warn if being compiled on a platform where this is unsafe
    dateFormatter = [NSDateFormatter new];

    // NB: hardcoding "-00:00" (UTC) as timezone
    // TODO this does not fully handle RFC 3339 dates. fractional seconds are optional
    // and timezone is fixed at UTC
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'-00:00'";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation: @"UTC"];
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
  [writer outputObject: [dateFormatter stringFromDate: value]];
}

- (id) readValue: (id) value
{
  if ([value isKindOfClass: [NSString class]])
  {
    NSDate *date = [dateFormatter dateFromString: value];

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
