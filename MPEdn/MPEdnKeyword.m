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

#import "MPEdnKeyword.h"

static NSCharacterSet *NON_KEYWORD_CHARS;
static NSMutableDictionary *ednKeywordTable;

@implementation MPEdnKeyword
{
  NSString *name;
}

+ (void) initialize
{
  if (self == [MPEdnKeyword class])
  {
    ednKeywordTable = [NSMutableDictionary new];

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

+ (BOOL) isValidKeyword: (NSString *) name
{
  return [name rangeOfCharacterFromSet: NON_KEYWORD_CHARS].location == NSNotFound;
}

- (instancetype) initWithName: (NSString *) initName
{
  if (![MPEdnKeyword isValidKeyword: initName])
  {
    [NSException raise: @"InvalidEDNKeyword"
                format: @"%@ is not a valid EDN keyword", initName];
  }
  
  if (self = [super init])
  {
    name = initName;
  }
  
  return self;
}

- (id) copyWithZone: (NSZone *) zone
{
  return self;
}

- (BOOL) isEqual: (id) object
{
  return self == object;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @":%@", name];
}

- (NSString *) ednName
{
  return name;
}

@end

@implementation NSString (MPEdn)

- (MPEdnKeyword *) ednKeyword
{
  @synchronized ([MPEdnKeyword class])
  {
    MPEdnKeyword *keyword = [ednKeywordTable objectForKey: self];
    
    if (!keyword)
    {
      keyword = [[MPEdnKeyword alloc] initWithName: self];
      
      [ednKeywordTable setObject: keyword forKey: self];
    }
    
    return keyword;
  }
}

- (NSString *) ednName
{
  return self;
}

@end