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

static MPEdnDateCodec *sharedInstance;

static NSDateFormatter *rfc3339DateFormat ()
{
  NSDateFormatter *formatter = [NSDateFormatter new];

  formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SS'Z'";
  formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation: @"UTC"];

  return formatter;
}

@implementation MPEdnDateCodec

+ (void) initialize
{
  if (self == [MPEdnDateCodec class])
  {
    sharedInstance = [MPEdnDateCodec new];
  }
}

+ (MPEdnDateCodec *) sharedInstance
{
  return sharedInstance;
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
  [writer outputObject: [rfc3339DateFormat () stringFromDate: value]];
}

- (id) readValue: (id) value
{
  if ([value isKindOfClass: [NSString class]])
  {
    NSDate *date = [rfc3339DateFormat () dateFromString: value];
    
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
