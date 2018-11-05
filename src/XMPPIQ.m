/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import "namespaces.h"
#import "XMPPIQ.h"

@implementation XMPPIQ
+ (instancetype)IQWithType: (OFString *)type
			ID: (OFString *)ID
{
	return [[[self alloc] initWithType: type
					ID: ID] autorelease];
}

- (instancetype)initWithType: (OFString *)type
			  ID: (OFString *)ID
{
	self = [super initWithName: @"iq"
			      type: type
				ID: ID];

	@try {
		if (![type isEqual: @"get"] && ![type isEqual: @"set"] &&
		    ![type isEqual: @"result"] && ![type isEqual: @"error"])
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (XMPPIQ *)resultIQ
{
	XMPPIQ *ret = [XMPPIQ IQWithType: @"result"
				      ID: [self ID]];
	[ret setTo: [self from]];
	[ret setFrom: nil];
	return ret;
}

- (XMPPIQ *)errorIQWithType: (OFString *)type
		  condition: (OFString *)condition
		       text: (OFString *)text
{
	XMPPIQ *ret = [XMPPIQ IQWithType: @"error"
				      ID: [self ID]];
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *error = [OFXMLElement elementWithName: @"error"
						  namespace: XMPP_NS_CLIENT];

	[error addAttributeWithName: @"type"
			stringValue: type];
	[error addChild: [OFXMLElement elementWithName: condition
					     namespace: XMPP_NS_STANZAS]];
	if (text)
		[error addChild: [OFXMLElement elementWithName: @"text"
						     namespace: XMPP_NS_STANZAS
						   stringValue: text]];
	[ret addChild: error];
	[ret setTo: [self from]];
	[ret setFrom: nil];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (XMPPIQ *)errorIQWithType: (OFString *)type
		  condition: (OFString *)condition
{
	return [self errorIQWithType: type
			   condition: condition
				text: nil];
}
@end
