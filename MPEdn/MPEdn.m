#import "MPEdn.h"
#import "MPEdnSymbol.h"

// A token is one of these or just a single character.
typedef enum
{
  TOKEN_NONE = 0xF00000,  // NB: outside UTF-16 range
  TOKEN_END,
  TOKEN_ERROR,
  TOKEN_SET_OPEN,
  TOKEN_NUMBER,
  TOKEN_STRING,
  TOKEN_NAME,
  TOKEN_KEYWORD,
  TOKEN_CHARACTER,
} Token;

static void appendCharacter (NSMutableString *str, unichar ch)
{
  [str appendString: [NSString stringWithCharacters: &ch length: 1]];
}

@implementation MPEdnParser

- (void) reset
{
  inputStr = nil;
  inputStrLen = 0;
  startIdx = 0;
  endIdx = 0;
  token = TOKEN_NONE;
  tokenValue = nil;
  error = nil;
}

- (void) raiseError: (NSInteger) code message: (NSString *) message, ...
{
  if (!error)
  {
    va_list args;
    va_start (args, message);
    
    NSString *desc = [[NSString alloc] initWithFormat: message arguments: args];

    va_end (args);

    token = TOKEN_ERROR;
    
    error = [[NSError alloc]
             initWithDomain: @"MPEdn" code: code
                                  userInfo: @{NSLocalizedDescriptionKey : desc}];
  }
}

- (void) setInputString: (NSString *) str
{
  [self reset];
  
  inputStr = str;
  inputStrLen = [inputStr length];
  
  [self nextToken];
}

- (NSString *) inputString
{
  return inputStr;
}

- (NSError *) error
{
  return error;
}

#pragma mark - Tokeniser

static BOOL is_sym_punct (unichar ch)
{
  // NB: '/' is added to the specified EDN set of punctuation allowed in
  // symbol names. The check for its valid use is done by the parser.
  return (ch >= '!' && ch <= '_' &&
          (ch == '!' || ch == '$' || ch == '%' || ch == '&' || ch == '*' ||
           ch == '+' || ch == '-' || ch == '.' || ch == '=' || ch == '?' ||
           ch == '_' || ch == '/' || ch == ':' || ch == '#'));
}

- (unichar) currentEndIdxChar
{
  return (endIdx < inputStrLen) ? [inputStr characterAtIndex: endIdx] : 0;
}

- (unichar) advanceStartIdx
{
  startIdx++;
  
  return (startIdx < inputStrLen) ? [inputStr characterAtIndex: startIdx] : 0;
}

- (unichar) advanceEndIdx
{
  endIdx++;
  
  return (endIdx < inputStrLen) ? [inputStr characterAtIndex: endIdx] : 0;
}

- (unichar) skipSpaceAndComments
{
  if (startIdx < inputStrLen)
  {
    unichar ch = [inputStr characterAtIndex: startIdx];
    
    // skip white space and comments
    while ((isspace (ch) || ch == ',' || ch == ';') && startIdx < inputStrLen)
    {
      if (ch == ';')
      {
        while (ch != '\n' && startIdx < inputStrLen)
          ch = [self advanceStartIdx];
        
        ch = [self advanceStartIdx];         // skip \n
      } else
      {
        ch = [self advanceStartIdx];
      }
    }

    endIdx = startIdx;

    return ch;
  } else
  {
    return 0;
  }
}

- (id) consumeToken
{
  id value = tokenValue;
  
  [self nextToken];
  
  return value;
}

// NB: this does not handle symbols and keywords containing Unicode code points
// > 0xFFFF (i.e. characters that require representation using UTF-16 surrogate
// pairs). It *does* however support all Unicode points in strings.
- (void) nextToken
{
  startIdx = endIdx;
  tokenValue = nil;
  unichar ch = [self skipSpaceAndComments];

  if (startIdx < inputStrLen)
  {
    unichar lookahead =
      startIdx + 1 < inputStrLen ? [inputStr characterAtIndex: startIdx + 1] : 0;

    if (ch == '{' || ch == '[' || ch == '(' || ch == '}' || ch == ']' || ch == ')')
    {
      token = ch;
      endIdx = startIdx + 1;
    } else if (ch == '"')
    {
      [self readStringToken];
    } else if (isdigit (ch))
    {
      [self readNumberToken];
    } else if (ch == '+' || ch == '-' || ch == '.')
    {
      if (isalpha (lookahead))
        [self readNameToken];
      else
        [self readNumberToken];
    } else if (ch == ':')
    {
      [self readKeywordToken];
    } else if (ch == '\\')
    {
      [self readCharacterToken];
    } else if (ch == '#')
    {
      if (lookahead == '{')
      {
        token = TOKEN_SET_OPEN;
        endIdx = startIdx + 2;
      } else if (lookahead == '_')
      {
        endIdx = startIdx + 2;
        [self nextToken];
        [self parseExpr];
        [self nextToken];
      } else
      {
        [self readTagName];
      }
    } else if (isalpha (ch) || is_sym_punct (ch))
    {
      [self readNameToken];
    } else
    {
      [self raiseError: ERROR_INVALID_TOKEN
               message: @"Unparseable character %C", ch];
    }
  } else
  {
    token = TOKEN_END;
  }
}

- (void) readNumberToken
{
  unichar ch = [inputStr characterAtIndex: endIdx];
  BOOL isFloat = NO;
  
  if (ch == '+' || ch == '-')
    ch = [self advanceEndIdx];
  
  while (isdigit (ch))
    ch = [self advanceEndIdx];
  
  if (ch == '.')
  {
    isFloat = YES;
    
    do
    {
      ch = [self advanceEndIdx];
    } while (isdigit (ch));
  }

  if (ch == 'e' || ch == 'E')
  {
    ch = [self advanceEndIdx];

    if (ch == '+' || ch == '-')
      ch = [self advanceEndIdx];
    
    while (isdigit (ch))
      ch = [self advanceEndIdx];
  }

  if (ch == 'm' || ch == 'M' || ch == 'n' || ch == 'N')
  {
    [self advanceEndIdx];
    
    [self raiseError: ERROR_UNSUPPORTED_FEATURE
             message: @"M and N number suffixes are not supported"];
    
    return;
  }

  // NB: NSNumberFormatter throws exceptions on error and may or may not parse
  // floats according to the spec. Using strtod and and strtol instead.
  NSString *numberStr =
    [inputStr substringWithRange: NSMakeRange (startIdx, endIdx - startIdx)];
                          
  const char *numberStrUtf8 =
    [numberStr cStringUsingEncoding: NSUTF8StringEncoding];
  
  char *numberStrEnd = (char *)numberStrUtf8;
  
  if (isFloat)
  {
    double number = strtod (numberStrUtf8, &numberStrEnd);
    
    if (numberStrEnd - numberStrUtf8 == endIdx - startIdx)
    {
      if ([numberStr characterAtIndex: [numberStr length] - 1] == '.')
      {
        // strtod happily allows "1." as a legal number
        [self raiseError: ERROR_INVALID_NUMBER
                 message: @"Trailing '.' on number: \"%@\"", numberStr];
      } else
      {
        token = TOKEN_NUMBER;
        tokenValue = [NSNumber numberWithDouble: number];
      }
    } else
    {
      [self raiseError: ERROR_INVALID_NUMBER
               message: @"Invalid floating point number: \"%@\"", numberStr];
    }
  } else
  {
    long int number = strtol (numberStrUtf8, &numberStrEnd, 10);
    
    if (numberStrEnd - numberStrUtf8 == endIdx - startIdx)
    {
      token = TOKEN_NUMBER;
      tokenValue = [NSNumber numberWithLong: number];
    } else
    {
      [self raiseError: ERROR_INVALID_NUMBER
               message: @"Invalid integer: \"%@\"", numberStr];
    }
  }
}

- (void) readCharacterToken
{
  
}

- (void) readNameToken
{
  unichar ch;
  
  do
  {
    ch = [self advanceEndIdx];
  } while (isalnum (ch) || is_sym_punct (ch));
  
  token = TOKEN_NAME;
  tokenValue =
    [inputStr substringWithRange: NSMakeRange (startIdx, endIdx - startIdx)];
}

// TODO intern strings?
- (void) readKeywordToken
{
  unichar ch;
  
  do
  {
    ch = [self advanceEndIdx];
  } while (isalnum (ch) || is_sym_punct (ch));
  
  NSInteger length = endIdx - startIdx - 1;
  
  if (length > 0)
  {
    token = TOKEN_KEYWORD;
    tokenValue =
      [inputStr substringWithRange: NSMakeRange (startIdx + 1, length)];
  } else
  {
    [self raiseError: ERROR_INVALID_KEYWORD
             message: @"Empty keyword not allowed"];
  }
}

- (void) readStringToken
{
  unichar ch = [self advanceEndIdx];  // skip "
  BOOL hasEscapes = NO;
  NSString *stringValue;
  
  // check for fast path for strings not needing escape processing
  while (ch != '"' && !hasEscapes && endIdx < inputStrLen)
  {
    if (ch == '\\')
    {
      hasEscapes = YES;
    } else
    {
      NSRange chRange = [inputStr rangeOfComposedCharacterSequenceAtIndex: endIdx];
      
      endIdx += chRange.length;
      ch = [self currentEndIdxChar];
    }
  }
  
  if (!hasEscapes)
  {
    // fast path: just make a substring
    stringValue =
      [inputStr substringWithRange: NSMakeRange (startIdx + 1, endIdx - startIdx - 1)];
  } else
  {
    // slow path: scan each character and append
    // TODO make this faster: use a character buffer rather than NSMutableString
    // to avoid creating lots of temp strings in appendString.
    NSMutableString *str = [[NSMutableString alloc] initWithCapacity: 30];

    // reset endIdx
    endIdx = startIdx;
    ch = [self advanceEndIdx];

    while (ch != '"' && endIdx < inputStrLen)
    {
      if (ch == '\\')
      {
        ch = [self advanceEndIdx];
        
        switch (ch)
        {
          case '\n':
            appendCharacter (str, '\n');
            break;
          case '\t':
            appendCharacter (str, '\t');
            break;
          case '\r':
            appendCharacter (str, '\r');
            break;
          case '\\':
            appendCharacter (str, '\\');
            break;
          case '"':
            appendCharacter (str, '"');
            break;
          default:
            [self raiseError: ERROR_INVALID_ESCAPE
                     message: @"Invalid escape sequence: \\%C", ch];
        }
        
        ch = [self advanceEndIdx];
      } else
      {
        NSRange chRange = [inputStr rangeOfComposedCharacterSequenceAtIndex: endIdx];
        
        [str appendString: [inputStr substringWithRange: chRange]];
        
        endIdx += chRange.length;
        ch = [self currentEndIdxChar];
      }
    }
    
    stringValue = str;
  }

  if (ch == '"')
  {
    [self advanceEndIdx]; // skip "
   
    if (!error)
    {
      token = TOKEN_STRING;
      tokenValue = stringValue;
    }
  } else
  {
    [self raiseError: ERROR_UNTERMINATED_STRING
             message: @"Unterminated string"];
  }
}

- (void) readTagName
{
  
}

#pragma mark - Parser

- (BOOL) complete
{
  [self skipSpaceAndComments];
  
  return startIdx >= inputStrLen;
}

- (id) parseString: (NSString *) str
{
  self.inputString = str;
  
  id value = [self parseNextValue];
  
  if (self.complete)
  {
    return value;
  } else
  {
    startIdx = endIdx = inputStrLen;

    [self raiseError: ERROR_MULTIPLE_VALUES
             message: @"More than one value supplied, but only one expected"];
    
    return nil;
  }
}

- (id) parseNextValue
{
  return [self parseExpr];
}

- (id) parseExpr
{
  switch (token)
  {
    case TOKEN_NUMBER:
    case TOKEN_STRING:
    case TOKEN_KEYWORD:
    case TOKEN_CHARACTER:
    {
      return [self consumeToken];
    }
    case TOKEN_NAME:
    {
      id value = [self consumeToken];
      
      // TODO check symbol namespace ('/) validity
      if ([value isEqualToString: @"true"])
        return @YES;
      else if ([value isEqualToString: @"false"])
        return @NO;
      if ([value isEqualToString: @"nil"])
        return [NSNull null];
      else
        return [MPEdnSymbol symbolWithName: value];
    }
    case TOKEN_SET_OPEN:
    {
      return [self parseSet];
    }
    case '{':
    {
      return [self parseMap];
    }
    case '[':
    case '(':
    {
      [self parseList];
    }
    default:
    {
      [self raiseError: ERROR_NO_EXPRESSION
               message: @"No value found in expression"];

      return nil;
    }
  }
}

- (NSSet *) parseSet
{
  NSMutableSet *set = [NSMutableSet new];
  
  [self nextToken];
  
  while (token != '}' && !error && endIdx < inputStrLen)
  {
    id value = [self parseExpr];
    
    if (value)
      [set addObject: value];
  }
  
  if (token == '}')
  {
    [self nextToken];
    
    return set;
  } else
  {
    [self raiseError: UNTERMINATED_SET
             message: @"Unterminated set (missing '}')"];
    
    return nil;
  }
}

- (NSDictionary *) parseMap
{
  
}

- (NSArray *) parseList
{
  
}

@end

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

