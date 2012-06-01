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
+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
{
	return [[[self alloc] initWithClass: class_
				 connection: conn] autorelease];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
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
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"An exception occurred in class %@!", inClass];

	return description;
}

- (XMPPConnection*)connection
{
	return connection;
}
@end

@implementation XMPPStreamErrorException
+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	   condition: (OFString*)condition_
	      reason: (OFString*)reason_;
{
	return [[[self alloc] initWithClass: class_
				 connection: conn
				  condition: condition_
				     reason: reason_] autorelease];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
      condition: (OFString*)condition_
	 reason: (OFString*)reason_
{
	self = [super initWithClass: class_
			 connection: conn];

	@try {
		condition = [condition_ copy];
		reason = [reason_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[condition release];
	[reason release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
		@"Got stream error: %@. Reason: %@!", condition, reason];

	return description;
}

- (OFString*)condition
{
	return condition;
}

- (OFString*)reason
{
	return reason;
}
@end

@implementation XMPPStringPrepFailedException
+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	     profile: (OFString*)profile
	      string: (OFString*)string
{
	return [[[self alloc] initWithClass: class_
				 connection: conn
				    profile: profile
				     string: string] autorelease];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
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
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Stringprep with profile %@ failed on string '%@'!",
	    profile, string];

	return description;
}

- (OFString*)profile
{
	return profile;
}

- (OFString*)string
{
	return string;
}
@end

@implementation XMPPIDNATranslationFailedException
+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	   operation: (OFString*)operation
	      string: (OFString*)string
{
	return [[[self alloc] initWithClass: class_
				 connection: conn
				  operation: operation
				     string: string] autorelease];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
      operation: (OFString*)operation_
	 string: (OFString*)string_
{
	self = [super initWithClass: class_
			 connection: conn];

	@try {
		operation = [operation_ copy];
		string = [string_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[operation release];
	[string release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"IDNA operation %@ failed on string '%@'!", operation, string];

	return description;
}

- (OFString*)operation
{
	return operation;
}

- (OFString*)string
{
	return string;
}
@end

@implementation XMPPAuthFailedException
+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	      reason: (OFString*)reason_;
{
	return [[[self alloc] initWithClass: class_
				 connection: conn
				     reason: reason_] autorelease];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
	 reason: (OFString*)reason_
{
	self = [super initWithClass: class_
			 connection: conn];

	@try {
		reason = [reason_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[reason release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Authentication failed. Reason: %@!", reason];

	return description;
}

- (OFString*)reason
{
	return reason;
}
@end
