#import "MPEdnSymbol.h"

@implementation MPEdnSymbol

+ (MPEdnSymbol *) symbolWithName: (NSString *) name
{
  return [[MPEdnSymbol alloc] initWithName: name];
}

- (id) initWithName: (NSString *) initName
{
  if (self = [super init])
  {
    name = initName;
  }
  
  return self;
}

- (NSString *) name
{
  return name;
}

- (BOOL) isEqual: (id) object
{
  return [object isKindOfClass: [MPEdnSymbol class]] &&
         [[object name] isEqualToString: name];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"Symbol: %@", name];
}

@end
