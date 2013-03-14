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
 * You must not remove this notice, or any other, from this software.
 */

#import "MPEdnWriter.h"
#import "MPEdnSymbol.h"

#import <objc/runtime.h>

const NSString *MPEDN_CHARACTER_TAG = @"MPEDN_CHARACTER_TAG";

NSNumber *MPEdnTagAsCharacter (NSNumber *number)
{
  objc_setAssociatedObject (number, (__bridge const void *)MPEDN_CHARACTER_TAG,
                            @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  return number;
}

BOOL MPEdnIsCharacter (NSNumber *number)
{
  return objc_getAssociatedObject (number, (__bridge const void *)MPEDN_CHARACTER_TAG) != nil;
}

static NSCharacterSet *QUOTE_CHARS;
static NSCharacterSet *NON_KEYWORD_CHARS;

@implementation MPEdnWriter

+ (void) initialize
{
  if (self == [MPEdnWriter class])
  {
    QUOTE_CHARS = [NSCharacterSet characterSetWithCharactersInString: @"\\\"\n\r"];
    
    NSMutableCharacterSet *nonKeywordChars =
      [NSMutableCharacterSet characterSetWithCharactersInString: @".*+!-_?$%&=/"];
    
    [nonKeywordChars addCharactersInRange: NSMakeRange ('a', 'z' - 'a' + 1)];
    [nonKeywordChars addCharactersInRange: NSMakeRange ('A', 'Z' - 'A' + 1)];
    [nonKeywordChars addCharactersInRange: NSMakeRange ('0', '9' - '0' + 1)];
    
    [nonKeywordChars invert];
    
    // make an immutable (faster) copy
    NON_KEYWORD_CHARS = [nonKeywordChars copy];
  }
}

- (id) init
{
  if (self = [super init])
  {
    useKeywordsInMaps = YES;
  }

  return self;
}

- (BOOL) useKeywordsInMaps
{
  return useKeywordsInMaps;
}

- (void) setUseKeywordsInMaps: (BOOL) newValue
{
  useKeywordsInMaps = newValue;
}

- (NSString *) serialiseToEdn: (id) value;
{
  outputStr = [NSMutableString new];
  
  [self outputObject: value];
  
  return outputStr;
}

- (void) outputObject: (id) value
{
  if (value == nil || value == [NSNull null])
    [outputStr appendString: @"nil"];
  else if ([value isKindOfClass: [NSNumber class]])
    [self outputNumber: value];
  else if ([value isKindOfClass: [NSString class]])
    [self outputString: value];
  else if ([value isKindOfClass: [NSDictionary class]])
    [self outputDictionary: value];
  else if ([value isKindOfClass: [NSArray class]])
    [self outputArray: value];
  else if ([value isKindOfClass: [NSSet class]])
    [self outputSet: value];
  else if ([value isKindOfClass: [MPEdnSymbol class]])
    [self outputSymbol: value];
  else
  {
    [NSException raise: @"MPEdnWriterException"
                format: @"Don't know how to handle value of type %@ ",
     [value class]];
  }
}

- (void) outputNumber: (NSNumber *) value
{
  switch ([value objCType] [0])
  {
    case 'i':
    case 'q':
    case 's':
      if (MPEdnIsCharacter (value))
        [outputStr appendFormat: @"\\%c", [value charValue]];
      else
        [outputStr appendFormat: @"%@", value];
      break;
    case 'd':
      [outputStr appendFormat: @"%.15E", [value doubleValue]];
      break;
    case 'f':
      [outputStr appendFormat: @"%.7E", [value doubleValue]];
      break;
    case 'c':
    {
      if ([NSStringFromClass ([value class]) isEqualToString: @"__NSCFBoolean"])
        [outputStr appendString: [value boolValue] ? @"true" : @"false"];
      else
        [outputStr appendFormat: @"\\%c", [value charValue]];

      break;
    default:
      [NSException raise: @"MPEdnWriterException"
                  format: @"Don't know how to handle NSNumber "
                           "value %@, class %@", value, [value class]];
    }
  }
}

- (void) outputString: (NSString *) value
{
  NSRange quoteRange = [value rangeOfCharacterFromSet: QUOTE_CHARS];
  
  if (quoteRange.location == NSNotFound)
  {
    [outputStr appendFormat: @"\"%@\"", value];
  } else
  {
    NSUInteger start = 0;
    NSUInteger valueLen = [value length];
    
    [outputStr appendString: @"\""];
    
    do
    {
      if (quoteRange.location > start)
        [outputStr appendString: [value substringWithRange: NSMakeRange (start, quoteRange.location - start)]];

      unichar quoteCh = [value characterAtIndex: quoteRange.location];
      
      switch (quoteCh)
      {
        case '\n':
          [outputStr appendString: @"\\n"];
          break;
        case '\r':
          [outputStr appendString: @"\\r"];
          break;
        default:
          [outputStr appendFormat: @"\\%C", quoteCh];
      }

      start = quoteRange.location + 1;
      
      if (start < valueLen)
      {
        quoteRange = [value rangeOfCharacterFromSet: QUOTE_CHARS
                                            options: NSLiteralSearch
                                              range: NSMakeRange (start, valueLen - start)];
      }
    } while (start < valueLen && quoteRange.location != NSNotFound);
    
    if (start < valueLen)
      [outputStr appendString: [value substringWithRange: NSMakeRange (start, valueLen - start)]];
    
    [outputStr appendString: @"\""];
  }
}

- (BOOL) outputKeyword: (NSString *) value
{
  if ([value rangeOfCharacterFromSet: NON_KEYWORD_CHARS].location == NSNotFound)
  {
    [outputStr appendString: @":"];
    [outputStr appendString: value];
    
    return YES;
  } else
  {
    return NO;
  }
}

- (void) outputDictionary: (NSDictionary *) value
{
  BOOL firstItem = YES;

  [outputStr appendString: @"{"];

  for (id key in value)
  {
    if (!firstItem)
      [outputStr appendString: @","];
    
    if (useKeywordsInMaps && [key isKindOfClass: [NSString class]])
    {
      if (![self outputKeyword: key])
        [self outputObject: key];
    } else
    {
      [self outputObject: key];
    }

    [outputStr appendString: @" "];
    
    [self outputObject: [value objectForKey: key]];
    
    firstItem = NO;
  }
  
  [outputStr appendString: @"}"];
}

- (void) outputArray: (NSArray *) value
{
  BOOL firstItem = YES;
  
  [outputStr appendString: @"["];
  
  for (id item in value)
  {
    if (!firstItem)
      [outputStr appendString: @","];
    
    [self outputObject: item];
    
    firstItem = NO;
  }
  
  [outputStr appendString: @"]"];
}

- (void) outputSet: (NSSet *) value
{
  BOOL firstItem = YES;
  
  [outputStr appendString: @"#{"];
  
  for (id item in value)
  {
    if (!firstItem)
      [outputStr appendString: @","];
    
    [self outputObject: item];
    
    firstItem = NO;
  }
  
  [outputStr appendString: @"}"];
}

- (void) outputSymbol: (MPEdnSymbol *) value
{
  [outputStr appendString: value.name];
}

@end

@implementation NSObject (MPEdn)

- (NSString *) objectToEdnString
{
  return [[MPEdnWriter new] serialiseToEdn: self];
}

@end
