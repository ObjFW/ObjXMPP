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

#import "XMPPRoster.h"
#import "XMPPRosterItem.h"
#import "XMPPConnection.h"
#import "XMPPIQ.h"
#import "XMPPJID.h"

@implementation XMPPRoster
- initWithConnection: (XMPPConnection*)conn
{
	self = [super init];

	@try {
		connection = [conn retain];
		rosterItems = [[OFMutableDictionary alloc] init];
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

- (void)XMPP_addRosterItem: (XMPPRosterItem*)rosterItem
{
	return [self XMPP_updateRosterItem: rosterItem];
}

- (void)XMPP_updateRosterItem: (XMPPRosterItem*)rosterItem
{
	[rosterItems setObject: rosterItem
			forKey: [[rosterItem JID] bareJID]];
}

- (void)XMPP_deleteRosterItem: (XMPPRosterItem*)rosterItem
{
	[rosterItems removeObjectForKey: [[rosterItem JID] bareJID]];
}

- (OFDictionary*)rosterItems
{
	return [[rosterItems copy] autorelease];
}

- (void)addRosterItem: (XMPPRosterItem*)rosterItem
{
	[self updateRosterItem: rosterItem];
}

- (void)updateRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *iq = [XMPPIQ IQWithType: @"set"
				     ID: [connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPP_NS_ROSTER];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPP_NS_ROSTER];
	OFEnumerator *enumerator;
	OFString *group;

	[item addAttributeWithName: @"jid"
		       stringValue: [[rosterItem JID] bareJID]];
	if ([rosterItem name] != nil)
		[item addAttributeWithName: @"name"
			       stringValue: [rosterItem name]];

	enumerator = [[rosterItem groups] objectEnumerator];
	while ((group = [enumerator nextObject]) != nil)
		[item addChild: [OFXMLElement elementWithName: @"group"
						    namespace: XMPP_NS_ROSTER
						  stringValue: group]];

	[query addChild: item];
	[iq addChild: query];

	[connection sendStanza: iq];
}

- (void)deleteRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *iq = [XMPPIQ IQWithType: @"set"
				     ID: [connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPP_NS_ROSTER];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPP_NS_ROSTER];

	[item addAttributeWithName: @"jid"
		       stringValue: [[rosterItem JID] bareJID]];
	[item addAttributeWithName: @"subscription"
		       stringValue: @"remove"];

	[query addChild: item];
	[iq addChild: query];

	[connection sendStanza: iq];
}
@end
