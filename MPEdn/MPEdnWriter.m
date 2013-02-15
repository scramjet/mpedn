#import "MPEdnWriter.h"

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
