/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@heap.zone>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://heap.zone/objxmpp/
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

#include <stdlib.h>

#import "XMPPExceptions.h"
#import "XMPPConnection.h"

@implementation XMPPException
@synthesize connection = _connection;

+ (instancetype)exceptionWithConnection: (XMPPConnection*)connection
{
	return [[[self alloc] initWithConnection: connection] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithConnection: (XMPPConnection*)connection
{
	self = [super init];

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
@end

@implementation XMPPStreamErrorException
@synthesize condition = _condition, reason = _reason;

+ (instancetype)exceptionWithConnection: (XMPPConnection*)connection
			      condition: (OFString*)condition
				 reason: (OFString*)reason;
{
	return [[[self alloc] initWithConnection: connection
				       condition: condition
					  reason: reason] autorelease];
}

- initWithConnection: (XMPPConnection*)connection
{
	OF_INVALID_INIT_METHOD
}

- initWithConnection: (XMPPConnection*)connection
	   condition: (OFString*)condition
	      reason: (OFString*)reason
{
	self = [super initWithConnection: connection];

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
	    @"Got stream error: %@. Reason: %@!", _condition, _reason];
}
@end

@implementation XMPPStringPrepFailedException
@synthesize profile = _profile, string = _string;

+ (instancetype)exceptionWithConnection: (XMPPConnection*)connection
				profile: (OFString*)profile
				 string: (OFString*)string
{
	return [[[self alloc] initWithConnection: connection
					 profile: profile
					  string: string] autorelease];
}

- initWithConnection: (XMPPConnection*)connection
{
	OF_INVALID_INIT_METHOD
}

- initWithConnection: (XMPPConnection*)connection
	     profile: (OFString*)profile
	      string: (OFString*)string
{
	self = [super initWithConnection: connection];

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
	    @"Stringprep with profile %@ failed on string '%@'!",
	    _profile, _string];
}
@end

@implementation XMPPIDNATranslationFailedException
@synthesize operation = _operation, string = _string;

+ (instancetype)exceptionWithConnection: (XMPPConnection*)connection
			      operation: (OFString*)operation
				 string: (OFString*)string
{
	return [[[self alloc] initWithConnection: connection
				       operation: operation
					  string: string] autorelease];
}

- initWithConnection: (XMPPConnection*)connection
{
	OF_INVALID_INIT_METHOD
}

- initWithConnection: (XMPPConnection*)connection
	   operation: (OFString*)operation
	      string: (OFString*)string
{
	self = [super initWithConnection: connection];

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
	    @"IDNA operation %@ failed on string '%@'!", _operation, _string];
}
@end

@implementation XMPPAuthFailedException
@synthesize reason = _reason;

+ (instancetype)exceptionWithConnection: (XMPPConnection*)connection
				 reason: (OFString*)reason;
{
	return [[[self alloc] initWithConnection: connection
					  reason: reason] autorelease];
}

- initWithConnection: (XMPPConnection*)connection
{
	OF_INVALID_INIT_METHOD
}

- initWithConnection: (XMPPConnection*)connection
	      reason: (OFString*)reason
{
	self = [super initWithConnection: connection];

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
	    @"Authentication failed. Reason: %@!", _reason];
}
@end
