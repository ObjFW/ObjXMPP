/*
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2019, 2021, Jonathan Schleifer <js@nil.im>
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

#include <inttypes.h>

#import "XMPPStreamManagement.h"
#import "namespaces.h"

@implementation XMPPStreamManagement
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithConnection: (XMPPConnection *)connection
{
	self = [super init];

	@try {
		_connection = connection;
		[_connection addDelegate: self];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_connection removeDelegate: self];

	[super dealloc];
}

- (void)connection: (XMPPConnection *)connection
 didReceiveElement: (OFXMLElement *)element
{
	OFString *elementName = element.name;
	OFString *elementNS = element.namespace;

	if ([elementNS isEqual: XMPPSMNS]) {
		if ([elementName isEqual: @"enabled"]) {
			_receivedCount = 0;
			return;
		}

		if ([elementName isEqual: @"failed"]) {
			/* TODO: How do we handle this? */
			return;
		}

		if ([elementName isEqual: @"r"]) {
			OFXMLElement *ack =
			    [OFXMLElement elementWithName: @"a"
						namespace: XMPPSMNS];
			OFString *stringValue = [OFString
			    stringWithFormat: @"%" PRIu32, _receivedCount];
			[ack addAttributeWithName: @"h"
				      stringValue: stringValue];
			[connection sendStanza: ack];
		}
	}

	if ([elementNS isEqual: XMPPClientNS] &&
	    ([elementName isEqual: @"iq"] ||
	     [elementName isEqual: @"presence"] ||
	     [elementName isEqual: @"message"]))
		_receivedCount++;
}

/* TODO: Count outgoing stanzas here and cache them, send own ACK requests
- (void)connection: (XMPPConnection *)connection
    didSendElement: (OFXMLElement *)element
{
}
*/

- (void)connection: (XMPPConnection *)connection wasBoundToJID: (XMPPJID *)JID
{
	if (connection.supportsStreamManagement)
		[connection sendStanza:
		    [OFXMLElement elementWithName: @"enable"
					namespace: XMPPSMNS]];
}
@end
