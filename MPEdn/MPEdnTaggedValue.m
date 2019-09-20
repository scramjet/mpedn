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

#import "MPEdnTaggedValue.h"

@implementation MPEdnTaggedValue

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (instancetype) initWithTag: (NSString *) tag value: (id) value
{
  if (self = [super init])
  {
    _tag = tag;
    _value = value;
  }
  
  return self;
}

- (instancetype) initWithCoder: (NSCoder *) coder
{
  return [self initWithTag: [coder decodeObjectOfClass: [NSString class] forKey: @"tag"]
                     value: [coder decodeObjectOfClass: [NSObject class] forKey: @"value"]];
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeObject: _tag forKey: @"tag"];
  [coder encodeObject: _value forKey: @"value"];
}

@end
