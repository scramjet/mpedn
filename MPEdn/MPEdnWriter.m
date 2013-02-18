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

@implementation MPEdnWriter

- (NSString *) serialiseToEdn: (id) value;
{
  outputStr = [NSMutableString new];
  
  if (value == nil || value == [NSNull null])
    [outputStr appendString: @"nil"];
  else if ([value isKindOfClass: [NSNumber class]])
    [self outputNumber: value];

  return outputStr;
}

- (void) outputNumber: (NSNumber *) value
{
  NSLog (@"*** type %@", NSStringFromClass ([value class]));
  
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

@end
