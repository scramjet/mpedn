#import "MPEdnWriter.h"

@implementation MPEdnWriter

- (NSString *) serialiseToEdn: (id) value;
{
  outputStr = [NSMutableString new];
  
  if ([value isKindOfClass: [NSNumber class]])
    [self outputNumber: value];
  
  return outputStr;
}

- (void) outputNumber: (NSNumber *) value
{
  char type = *[value objCType];
  NSLog (@"**** type %c", type);
  
  switch (type)
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
  }
}

@end
