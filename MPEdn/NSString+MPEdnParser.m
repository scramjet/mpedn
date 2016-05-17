#import "MPEdnParser.h"
#import "NSString+MPEdnParser.h"

@implementation NSString (MPEdnParser)

- (id) ednStringToObject
{
  return [[MPEdnParser new] parseString: self];
}

- (id) ednStringToObjectNoKeywords
{
  MPEdnParser *parser = [MPEdnParser new];
  
  parser.keywordsAsStrings = YES;
  
  return [parser parseString: self];
}

@end