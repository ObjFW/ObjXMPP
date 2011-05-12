/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import "namespaces.h"
#import "XMPPIQ.h"

@implementation XMPPIQ
+ IQWithType: (OFString*)type_
	  ID: (OFString*)ID_
{
	return [[[self alloc] initWithType: type_
					ID: ID_] autorelease];
}

- initWithType: (OFString*)type_
	    ID: (OFString*)ID_
{
	self = [super initWithName: @"iq"
			      type: type_
				ID: ID_];

	@try {
		if (![type_ isEqual: @"get"] && ![type_ isEqual: @"set"] &&
		    ![type_ isEqual: @"result"] && ![type_ isEqual: @"error"])
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (XMPPIQ*)resultIQ
{
	XMPPIQ *ret = [XMPPIQ IQWithType: @"result"
				      ID: [self ID]];
	[ret setTo: [self from]];
	[ret setFrom: nil];
	return ret;
}

- (XMPPIQ*)errorIQWithType: (OFString*)type_
		 condition: (OFString*)condition
		      text: (OFString*)text
{
	XMPPIQ *ret = [XMPPIQ IQWithType: @"error"
				      ID: [self ID]];
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *error = [OFXMLElement elementWithName: @"error"
						  namespace: XMPP_NS_CLIENT];

	[error addAttributeWithName: @"type"
			stringValue: type_];
	[error addChild: [OFXMLElement elementWithName: condition
					     namespace: XMPP_NS_STANZAS]];
	if (text)
		[error addChild: [OFXMLElement elementWithName: @"text"
						     namespace: XMPP_NS_STANZAS
						   stringValue: text]];
	[ret addChild: error];
	[ret setTo: [self from]];
	[ret setFrom: nil];

	[pool release];

	return ret;
}

- (XMPPIQ*)errorIQWithType: (OFString*)type_
		 condition: (OFString*)condition
{
	return [self errorIQWithType: type_
			   condition: condition
				text: nil];
}
@end
