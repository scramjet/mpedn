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

#import "MPEdnCharacter.h"

@implementation MPEdnCharacter
{
  unichar character;
}

@synthesize character;

+ (MPEdnCharacter *) character: (unichar) ch
{
  return [[MPEdnCharacter alloc] initWithCharacter: ch];
}

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (instancetype) initWithCharacter: (unichar) ch
{
  if (self = [super init])
  {
    character = ch;
  }

  return self;
}

- (instancetype) initWithCoder: (NSCoder *) coder
{
  return [[MPEdnCharacter alloc] initWithCharacter: [coder decodeIntForKey: @"ch"]];
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeInt: character forKey: @"ch"];
}

- (id) copyWithZone: (NSZone *) zone
{
  return self;
}

- (BOOL) isEqual: (id) object
{
  return self == object ||
         ([object isKindOfClass: [MPEdnCharacter class]] &&
          character == ((MPEdnCharacter *)object)->character);
}

- (NSComparisonResult) compare: (MPEdnCharacter *) object
{
  if ([object isKindOfClass: [MPEdnCharacter class]])
  {
    return (NSInteger)character - (NSInteger)((MPEdnCharacter *)object)->character;
  } else
  {
    return -1;
  }
}

- (NSString *) description
{
  return [self stringValue];
}

- (NSString *) stringValue
{
  return [NSString stringWithFormat: @"\\%C", character];
}

@end
