/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 *
 * https://webkeks.org/git/?p=objxmpp.git
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "XMPPExceptions.h"
#import "XMPPConnection.h"

@implementation XMPPException
+ exceptionWithClass: (Class)class
	  connection: (XMPPConnection*)connection
{
	return [[[self alloc] initWithClass: class
				 connection: connection] autorelease];
}

- initWithClass: (Class)class
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
{
	self = [super initWithClass: class];

	@try {
		_connection = [connection retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_connection release];

	[super dealloc];
}

- (XMPPConnection*)connection
{
	OF_GETTER(_connection, NO)
}
@end

@implementation XMPPStreamErrorException
+ exceptionWithClass: (Class)class
	  connection: (XMPPConnection*)connection
	   condition: (OFString*)condition
	      reason: (OFString*)reason;
{
	return [[[self alloc] initWithClass: class
				 connection: connection
				  condition: condition
				     reason: reason] autorelease];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
      condition: (OFString*)condition
	 reason: (OFString*)reason
{
	self = [super initWithClass: class
			 connection: connection];

	@try {
		_condition = [condition copy];
		_reason = [reason copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_condition release];
	[_reason release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Got stream error in class %@: %@. Reason: %@!", [self inClass],
	    _condition, _reason];
}

- (OFString*)condition
{
	OF_GETTER(_condition, NO)
}

- (OFString*)reason
{
	OF_GETTER(_reason, NO)
}
@end

@implementation XMPPStringPrepFailedException
+ exceptionWithClass: (Class)class
	  connection: (XMPPConnection*)connection
	     profile: (OFString*)profile
	      string: (OFString*)string
{
	return [[[self alloc] initWithClass: class
				 connection: connection
				    profile: profile
				     string: string] autorelease];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
	profile: (OFString*)profile
	 string: (OFString*)string
{
	self = [super initWithClass: class
			 connection: connection];

	@try {
		_profile = [profile copy];
		_string = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_profile release];
	[_string release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Stringprep with profile %@ failed in class %@ on string '%@'!",
	    _profile, [self inClass], _string];
}

- (OFString*)profile
{
	OF_GETTER(_profile, NO)
}

- (OFString*)string
{
	OF_GETTER(_string, NO)
}
@end

@implementation XMPPIDNATranslationFailedException
+ exceptionWithClass: (Class)class
	  connection: (XMPPConnection*)connection
	   operation: (OFString*)operation
	      string: (OFString*)string
{
	return [[[self alloc] initWithClass: class
				 connection: connection
				  operation: operation
				     string: string] autorelease];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
      operation: (OFString*)operation
	 string: (OFString*)string
{
	self = [super initWithClass: class
			 connection: connection];

	@try {
		_operation = [operation copy];
		_string = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_operation release];
	[_string release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"IDNA operation %@ failed in class %@ on string '%@'!", _operation,
	    [self inClass], _string];
}

- (OFString*)operation
{
	OF_GETTER(_operation, NO)
}

- (OFString*)string
{
	OF_GETTER(_string, NO)
}
@end

@implementation XMPPAuthFailedException
+ exceptionWithClass: (Class)class
	  connection: (XMPPConnection*)connection
	      reason: (OFString*)reason;
{
	return [[[self alloc] initWithClass: class
				 connection: connection
				     reason: reason] autorelease];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class
     connection: (XMPPConnection*)connection
	 reason: (OFString*)reason
{
	self = [super initWithClass: class
			 connection: connection];

	@try {
		_reason = [reason copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_reason release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Authentication failed in class %@. Reason: %@!", [self inClass],
	    _reason];
}

- (OFString*)reason
{
	OF_GETTER(_reason, NO)
}
@end
