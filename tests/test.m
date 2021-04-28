/*
 * Copyright (c) 2010, 2011, 2019, 2021, Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
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

#include <assert.h>

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"
#import "XMPPDiscoEntity.h"
#import "XMPPDiscoIdentity.h"
#import "XMPPJID.h"
#import "XMPPStanza.h"
#import "XMPPIQ.h"
#import "XMPPMessage.h"
#import "XMPPPresence.h"
#import "XMPPRoster.h"
#import "XMPPStreamManagement.h"
#import "XMPPFileStorage.h"

@interface AppDelegate: OFObject
    <OFApplicationDelegate, XMPPConnectionDelegate, XMPPRosterDelegate>
{
	XMPPConnection *conn;
	XMPPRoster *roster;
}
@end

OF_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate
- (void)applicationDidFinishLaunching
{
	OFArray *arguments = [OFApplication arguments];

	XMPPPresence *pres = [XMPPPresence presence];
	pres.show = @"xa";
	pres.status = @"Bored";
	pres.priority = [OFNumber numberWithChar: 20];
	pres.to = [XMPPJID JIDWithString: @"alice@example.com"];
	pres.from = [XMPPJID JIDWithString: @"bob@example.org"];
	assert([pres.XMLString isEqual: @"<presence to='alice@example.com' "
	    @"from='bob@example.org'><show>xa</show>"
	    @"<status>Bored</status><priority>20</priority>"
	    @"</presence>"]);

	XMPPPresence *pres2 = [XMPPPresence presence];
	pres2.show = @"away";
	pres2.status = @"Bored";
	pres2.priority = [OFNumber numberWithChar: 23];
	pres2.to = [XMPPJID JIDWithString: @"alice@example.com"];
	pres2.from = [XMPPJID JIDWithString: @"bob@example.org"];

	assert([pres compare: pres2] == OFOrderedAscending);

	XMPPMessage *msg = [XMPPMessage messageWithType: @"chat"];
	msg.body = @"Hello everyone";
	msg.to = [XMPPJID JIDWithString: @"jdev@conference.jabber.org"];
	msg.from = [XMPPJID JIDWithString: @"alice@example.com"];
	assert([msg.XMLString isEqual: @"<message type='chat' "
	    @"to='jdev@conference.jabber.org' "
	    @"from='alice@example.com'><body>Hello everyone</body>"
	    @"</message>"]);

	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set"
				     ID: @"128"];
	IQ.to = [XMPPJID JIDWithString: @"juliet@capulet.lit"];
	IQ.from = [XMPPJID JIDWithString: @"romeo@montague.lit"];
	assert([IQ.XMLString isEqual: @"<iq type='set' id='128' "
	    @"to='juliet@capulet.lit' "
	    @"from='romeo@montague.lit'/>"]);

	OFXMLElement *elem = [OFXMLElement elementWithName: @"iq"];
	[elem addAttributeWithName: @"from"
		       stringValue: @"bob@localhost"];
	[elem addAttributeWithName: @"to"
		       stringValue: @"alice@localhost"];
	[elem addAttributeWithName: @"type"
		       stringValue: @"get"];
	[elem addAttributeWithName: @"id"
		       stringValue: @"42"];
	XMPPStanza *stanza = [XMPPStanza stanzaWithElement: elem];
	assert([elem.XMLString isEqual: [stanza XMLString]]);
	assert(([[OFString stringWithFormat: @"%@, %@, %@, %@",
	    stanza.from.fullJID, stanza.to.fullJID, stanza.type, stanza.ID]
	    isEqual: @"bob@localhost, alice@localhost, get, 42"]));


	conn = [[XMPPConnection alloc] init];
	[conn addDelegate: self];

	XMPPFileStorage *storage =
	    [[XMPPFileStorage alloc] initWithFile: @"storage.binarypack"];
	conn.dataStorage = storage;

	roster = [[XMPPRoster alloc] initWithConnection: conn];
	[roster addDelegate: self];

	[[XMPPStreamManagement alloc] initWithConnection: conn];

	if (arguments.count != 3) {
		OFLog(@"Invalid count of command line arguments!");
		[OFApplication terminateWithStatus: 1];
	}

	conn.domain = [arguments objectAtIndex: 0];
	conn.username = [arguments objectAtIndex: 1];
	conn.password = [arguments objectAtIndex: 2];
	conn.resource = @"ObjXMPP";

	[conn asyncConnect];
}

-  (void)connection: (XMPPConnection *)conn
  didReceiveElement: (OFXMLElement *)element
{
	OFLog(@"In:  %@", element);
}

- (void)connection: (XMPPConnection *)conn
    didSendElement: (OFXMLElement *)element
{
	OFLog(@"Out: %@", element);
}

- (void)connectionWasAuthenticated: (XMPPConnection *)conn
{
	OFLog(@"Auth successful");
}

- (void)connection: (XMPPConnection *)conn_
     wasBoundToJID: (XMPPJID *)JID
{
	OFLog(@"Bound to JID: %@", JID.fullJID);
	OFLog(@"Supports SM: %@",
	    conn_.supportsStreamManagement ? @"true" : @"false");

	XMPPDiscoEntity *discoEntity =
	    [[XMPPDiscoEntity alloc] initWithConnection: conn];

	[discoEntity addIdentity:
	    [XMPPDiscoIdentity identityWithCategory: @"client"
					       type: @"pc"
					       name: @"ObjXMPP"]];

	XMPPDiscoNode *nodeMusic =
	    [XMPPDiscoNode discoNodeWithJID: JID
				       node: @"music"
				       name: @"My music"];
	[discoEntity addChildNode: nodeMusic];

	XMPPDiscoNode *nodeRHCP =
	    [XMPPDiscoNode discoNodeWithJID: JID
				       node: @"fa3b6"
				       name: @"Red Hot Chili Peppers"];
	[nodeMusic addChildNode: nodeRHCP];

	XMPPDiscoNode *nodeStop =
	    [XMPPDiscoNode discoNodeWithJID: JID
				       node: @"qwe87"
				       name: @"Can't Stop"];
	[nodeRHCP addChildNode: nodeStop];

	XMPPDiscoNode *nodeClueso = [XMPPDiscoNode discoNodeWithJID: JID
							       node: @"ea386"
							       name: @"Clueso"];
	[nodeMusic addChildNode: nodeClueso];

	XMPPDiscoNode *nodeChicago = [XMPPDiscoNode discoNodeWithJID: JID
							      node: @"qwr87"
							      name: @"Chicago"];
	[nodeClueso addChildNode: nodeChicago];

	[discoEntity addDiscoNode: nodeMusic];
	[discoEntity addDiscoNode: nodeRHCP];
	[discoEntity addDiscoNode: nodeClueso];
	[discoEntity addDiscoNode: nodeStop];
	[discoEntity addDiscoNode: nodeChicago];

	[roster requestRoster];
}

- (void)rosterWasReceived: (XMPPRoster *)roster_
{
	XMPPPresence *pres;

	OFLog(@"Got roster: %@", roster_.rosterItems);

	pres = [XMPPPresence presence];
	pres.priority = [OFNumber numberWithChar: 10];
	pres.status = @"ObjXMPP test is working!";

	[conn sendStanza: pres];

#ifdef OF_HAVE_BLOCKS
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"get"
				     ID: [conn generateStanzaID]];
	[IQ addChild: [OFXMLElement elementWithName: @"ping"
					  namespace: @"urn:xmpp:ping"]];
	[conn	   sendIQ: IQ
	    callbackBlock: ^ (XMPPConnection *c, XMPPIQ *resp) {
		OFLog(@"Ping response: %@", resp);
	}];
#endif
}

- (void)connectionDidUpgradeToTLS: (XMPPConnection *)conn_
{
	OFString *reason;

	if (![conn_ checkCertificateAndGetReason: &reason]) {
		[OFStdOut writeString: @"Couldn't verify certificate: "];
		[OFStdOut writeFormat: @"%@\n", reason];
		[OFStdOut writeString: @"Do you want to continue [y/N]? "];

		if (![[OFStdIn readLine] hasPrefix: @"y"])
			[OFApplication terminateWithStatus: 1];
	}
}

-         (void)roster: (XMPPRoster *)roster_
  didReceiveRosterItem: (XMPPRosterItem *)rosterItem
{
	OFLog(@"Got roster push: %@", rosterItem);
}

- (bool)connection: (XMPPConnection *)conn
      didReceiveIQ: (XMPPIQ *)iq
{
	OFLog(@"IQ: %@", iq);

	return NO;
}

-  (void)connection: (XMPPConnection *)conn
  didReceiveMessage: (XMPPMessage *)msg
{
	OFLog(@"Message: %@", msg);
}

-   (void)connection: (XMPPConnection *)conn
  didReceivePresence: (XMPPPresence *)pres
{
	OFLog(@"Presence: %@", pres);
}

-  (void)connection: (XMPPConnection *)conn
  didThrowException: (id)e
{
	@throw e;
}

- (void)connectionWasClosed: (XMPPConnection *)conn
		      error: (OFXMLElement *)error
{
	OFLog(@"Connection was closed: %@", error);
}
@end
