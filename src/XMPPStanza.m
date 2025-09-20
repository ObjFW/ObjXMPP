/*
 * Copyright (c) 2011, 2012, 2013, 2019, 2021, 2025,
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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

#include "config.h"

#import "XMPPStanza.h"
#import "XMPPJID.h"
#import "namespaces.h"

@implementation XMPPStanza
@synthesize from = _from, to = _to, type = _type, ID = _ID;
@synthesize language = _language;

+ (instancetype)stanzaWithName: (OFString *)name
{
	return [[[self alloc] initWithName: name] autorelease];
}

+ (instancetype)stanzaWithName: (OFString *)name type: (OFString *)type
{
	return [[[self alloc] initWithName: name type: type] autorelease];
}

+ (instancetype)stanzaWithName: (OFString *)name ID: (OFString *)ID
{
	return [[[self alloc] initWithName: name ID: ID] autorelease];
}

+ (instancetype)stanzaWithName: (OFString *)name
			  type: (OFString *)type
			    ID: (OFString *)ID
{
	return [[[self alloc] initWithName: name
				      type: type
					ID: ID] autorelease];
}

+ (instancetype)stanzaWithElement: (OFXMLElement *)element
{
	return [[[self alloc] initWithElement: element] autorelease];
}

- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name namespace: (OFString *)namespace
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)namespace
		 stringValue: (nullable OFString *)stringValue
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithXMLString: (OFString *)string
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithFile: (OFString *)path
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
{
	return [self initWithName: name type: nil ID: nil];
}

- (instancetype)initWithName: (OFString *)name type: (OFString *)type
{
	return [self initWithName: name type: type ID: nil];
}

- (instancetype)initWithName: (OFString *)name
			  ID: (OFString *)ID
{
	return [self initWithName: name type: nil ID: ID];
}

- (instancetype)initWithName: (OFString *)name
			type: (OFString *)type
			  ID: (OFString *)ID
{
	self = [super initWithName: name
			 namespace: XMPPClientNS
		       stringValue: nil];

	@try {
		if (![name isEqual: @"iq"] && ![name isEqual: @"message"] &&
		    ![name isEqual: @"presence"])
			@throw [OFInvalidArgumentException exception];

		[self setPrefix: @"stream" forNamespace: XMPPStreamNS];

		if (type != nil)
			self.type = type;

		if (ID != nil)
			self.ID = ID;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithElement: (OFXMLElement *)element
{
	self = [super initWithElement: element];

	@try {
		OFXMLAttribute *attribute;

		if ((attribute = [element attributeForName: @"from"]))
			self.from =
			    [XMPPJID JIDWithString: attribute.stringValue];

		if ((attribute = [element attributeForName: @"to"]))
			self.to =
			    [XMPPJID JIDWithString: attribute.stringValue];

		if ((attribute = [element attributeForName: @"type"]))
			self.type = attribute.stringValue;

		if ((attribute = [element attributeForName: @"id"]))
			self.ID = attribute.stringValue;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_from release];
	[_to release];
	[_type release];
	[_ID release];

	[super dealloc];
}

- (void)setFrom: (XMPPJID *)from
{
	XMPPJID *old = _from;
	_from = [from copy];
	[old release];

	[self removeAttributeForName: @"from"];

	if (from != nil)
		[self addAttributeWithName: @"from" stringValue: from.fullJID];
}

- (void)setTo: (XMPPJID *)to
{
	XMPPJID *old = _to;
	_to = [to copy];
	[old release];

	[self removeAttributeForName: @"to"];

	if (to != nil)
		[self addAttributeWithName: @"to" stringValue: to.fullJID];
}

- (void)setType: (OFString *)type
{
	OFString *old = _type;
	_type = [type copy];
	[old release];

	[self removeAttributeForName: @"type"];

	if (type != nil)
		[self addAttributeWithName: @"type" stringValue: type];
}

- (void)setID: (OFString *)ID
{
	OFString *old = _ID;
	_ID = [ID copy];
	[old release];

	[self removeAttributeForName: @"id"];

	if (ID != nil)
		[self addAttributeWithName: @"id" stringValue: ID];
}

- (void)setLanguage: (OFString *)language
{
	OFString *old = _language;
	_language = [language copy];
	[old release];

	[self removeAttributeForName: @"lang"
			   namespace: @"http://www.w3.org/XML/1998/namespace"];

	if (language != nil)
		[self addAttributeWithName: @"lang"
				 namespace: @"http://www.w3.org/XML/1998/"
					    @"namespace"
			       stringValue: language];
}
@end
