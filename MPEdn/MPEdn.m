#import "MPEdn.h"

@implementation NSString (MPEdn)

- (id) ednStringToObject
{
  return [[MPEdnParser new] parseString: self];
}

@end

@implementation NSObject (MPEdn)

- (NSString *) objectToEdnString
{
  return nil;
}

@end

