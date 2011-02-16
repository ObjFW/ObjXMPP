/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 *
 * https://webkeks.org/hg/objxmpp/
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

#import "XMPPExceptions.h"

@implementation XMPPException
@synthesize connection;

+ newWithClass: (Class)class_
    connection: (XMPPConnection*)conn
{
	return [[self alloc] initWithClass: class_
				connection: conn];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	self = [super initWithClass: class_];

	@try {
		connection = [conn retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[connection release];

	[super dealloc];
}

- (OFString*)description
{
	OFAutoreleasePool *pool;

	if (description != nil)
		return description;

	pool = [[OFAutoreleasePool alloc] init];
	description = [[OFString alloc] initWithFormat:
	    @"An exception occurred in class %@!", [self className]];
	[pool release];

	return description;
}
@end

@implementation XMPPStringPrepFailedException
@synthesize profile, string;

+ newWithClass: (Class)class_
    connection: (XMPPConnection*)conn
       profile: (OFString*)profile
	string: (OFString*)string
{
	return [[self alloc] initWithClass: class_
				connection: conn
				   profile: profile
				    string: string];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
	profile: (OFString*)profile_
	 string: (OFString*)string_
{
	self = [super initWithClass: class_
			 connection: conn];

	@try {
		profile = [profile_ copy];
		string = [string_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[profile release];
	[string release];

	[super dealloc];
}

- (OFString*)description
{
	OFAutoreleasePool *pool;

	if (description != nil)
		return description;

	pool = [[OFAutoreleasePool alloc] init];
	description = [[OFString alloc] initWithFormat:
	    @"Stringprep with profile %@ failed on string '%@'!",
	    profile, string];
	[pool release];

	return description;
}
@end
