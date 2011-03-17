/*
 * Copyright (c) 2010, 2011, Jonathan Schleifer <js@webkeks.org>
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

#include <assert.h>

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"
#import "XMPPJID.h"
#import "XMPPStanza.h"
#import "XMPPIQ.h"
#import "XMPPMessage.h"
#import "XMPPPresence.h"

@interface AppDelegate: OFObject <XMPPConnectionDelegate>
{
	XMPPConnection *conn;
}
@end

OF_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate
- (void)applicationDidFinishLaunching
{
	OFArray *arguments = [OFApplication arguments];

	XMPPPresence *pres = [XMPPPresence presence];
	[pres addShow: @"chat"];
	[pres addStatus: @"Bored"];
	[pres addPriority: 20];
	pres.to = [XMPPJID JIDWithString: @"alice@example.com"];
	pres.from = [XMPPJID JIDWithString: @"bob@example.org"];
	assert([[pres stringValue] isEqual: @"<presence to='alice@example.com' "
	    @"from='bob@example.org'><show>chat</show>"
	    @"<status>Bored</status><priority>20</priority>"
	    @"</presence>"]);

	XMPPMessage *msg = [XMPPMessage messageWithType: @"chat"];
	[msg addBody: @"Hello everyone"];
	msg.to = [XMPPJID JIDWithString: @"jdev@conference.jabber.org"];
	msg.from = [XMPPJID JIDWithString: @"alice@example.com"];
	assert([[msg stringValue] isEqual: @"<message type='chat' "
	    @"to='jdev@conference.jabber.org' "
	    @"from='alice@example.com'><body>Hello everyone</body>"
	    @"</message>"]);

	XMPPIQ *iq = [XMPPIQ IQWithType: @"set" ID: @"128"];
	iq.to = [XMPPJID JIDWithString: @"juliet@capulet.lit"];
	iq.from = [XMPPJID JIDWithString: @"romeo@montague.lit"];
	assert([[iq stringValue] isEqual: @"<iq type='set' id='128' "
	    @"to='juliet@capulet.lit' "
	    @"from='romeo@montague.lit'/>"]);

	OFXMLElement *elem = [OFXMLElement elementWithName: @"iq"];
	[elem addAttributeWithName: @"from" stringValue: @"bob@localhost"];
	[elem addAttributeWithName: @"to" stringValue: @"alice@localhost"];
	[elem addAttributeWithName: @"type" stringValue: @"get"];
	[elem addAttributeWithName: @"id" stringValue: @"42"];
	XMPPStanza *stanza = [XMPPStanza stanzaWithElement: elem];
	assert([[elem stringValue] isEqual: [stanza stringValue]]);
	assert(([[OFString stringWithFormat: @"%@, %@, %@, %@",
	    stanza.from.fullJID, stanza.to.fullJID, stanza.type, stanza.ID]
	    isEqual: @"bob@localhost, alice@localhost, get, 42"]));

	conn = [[XMPPConnection alloc] init];
	conn.delegate = self;

	if (arguments.count != 3) {
		of_log(@"Invalid count of command line arguments!");
		[OFApplication terminateWithStatus: 1];
	}

	[conn setServer: [arguments objectAtIndex: 0]];
	[conn setUsername: [arguments objectAtIndex: 1]];
	[conn setPassword: [arguments objectAtIndex: 2]];
	[conn setResource: @"ObjXMPP"];
	[conn setUseTLS: NO];

	[conn connect];
	@try {
		[conn handleConnection];
	} @catch (id e) {
		of_log(@"%@", e);
	}
}

- (void)connectionWasClosed: (XMPPConnection*)conn
{
	of_log(@"Connection was closed!");
}

- (void)connection: (XMPPConnection*)conn
      didReceiveIQ: (XMPPIQ*)iq
{
	of_log(@"IQ: %@", iq);
}

-  (void)connection: (XMPPConnection*)conn
  didReceiveMessage: (XMPPMessage*)msg
{
	of_log(@"Message: %@", msg);
}

-   (void)connection: (XMPPConnection*)conn
  didReceivePresence: (XMPPPresence*)pres
{
	of_log(@"Presence: %@", pres);
}
@end
