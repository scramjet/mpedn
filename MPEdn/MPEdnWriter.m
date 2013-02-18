#import "MPEdnWriter.h"

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

NSMutableCharacterSet *QUOTE_CHARS;

@implementation MPEdnWriter

+ (void) initialize
{
  [super initialize];
  
  QUOTE_CHARS = [NSMutableCharacterSet characterSetWithCharactersInString: @"\\\""];
}

- (NSString *) serialiseToEdn: (id) value;
{
  outputStr = [NSMutableString new];
  
  if (value == nil || value == [NSNull null])
    [outputStr appendString: @"nil"];
  else if ([value isKindOfClass: [NSNumber class]])
    [self outputNumber: value];
  else if ([value isKindOfClass: [NSString class]])
    [self outputString: value];
  else
  {
    [NSException raise: @"MPEdnWriterException"
                format: @"Don't know how to handle value of type %@ ",
                [value class]];
  }
  
  return outputStr;
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
    case 'f':
      [outputStr appendFormat: @"%g", [value doubleValue]];
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
      
      [outputStr appendFormat: @"\\%C", [value characterAtIndex: quoteRange.location]];
      
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

@end
