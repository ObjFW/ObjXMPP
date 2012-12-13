/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
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

#define XMPP_ROSTER_M

#include <assert.h>

#import <ObjFW/OFInvalidArgumentException.h>

#import "XMPPRoster.h"
#import "XMPPRosterItem.h"
#import "XMPPConnection.h"
#import "XMPPIQ.h"
#import "XMPPJID.h"
#import "XMPPMulticastDelegate.h"
#import "namespaces.h"

@implementation XMPPRoster
- initWithConnection: (XMPPConnection*)connection_
{
	self = [super init];

	@try {
		rosterItems = [[OFMutableDictionary alloc] init];
		connection = connection_;
		[connection addDelegate: self];
		delegates = [[XMPPMulticastDelegate alloc] init];
		dataStorage = [connection dataStorage];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[connection removeDelegate: self];
	[delegates release];
	[rosterItems release];

	[super dealloc];
}

- (OFDictionary*)rosterItems
{
	return [[rosterItems copy] autorelease];
}

- (void)requestRoster
{
	XMPPIQ *iq;
	OFXMLElement *query;

	rosterRequested = YES;

	iq = [XMPPIQ IQWithType: @"get"
			     ID: [connection generateStanzaID]];

	query = [OFXMLElement elementWithName: @"query"
				    namespace: XMPP_NS_ROSTER];

	if ([connection supportsRosterVersioning]) {
		OFString *ver = [dataStorage stringValueForPath: @"roster.ver"];

		if (ver == nil)
			ver = @"";

		[query addAttributeWithName: @"ver"
				stringValue: ver];
	}

	[iq addChild: query];

	[connection sendIQ: iq
	    callbackTarget: self
		  selector: @selector(XMPP_handleInitialRosterForConnection:
				IQ:)];
}

- (BOOL)connection: (XMPPConnection*)connection_
      didReceiveIQ: (XMPPIQ*)iq
{
	OFXMLElement *rosterElement;
	OFXMLElement *element;
	XMPPRosterItem *rosterItem;

	rosterElement = [iq elementForName: @"query"
				 namespace: XMPP_NS_ROSTER];

	if (rosterElement == nil)
		return NO;

	if (![[iq type] isEqual: @"set"])
		return NO;

	element = [rosterElement elementForName: @"item"
				      namespace: XMPP_NS_ROSTER];

	if (element != nil) {
		rosterItem = [self XMPP_rosterItemWithXMLElement: element];

		[delegates broadcastSelector: @selector(
						  roster:didReceiveRosterItem:)
				  withObject: self
				  withObject: rosterItem];

		[self XMPP_updateRosterItem: rosterItem];
	}

	if ([connection supportsRosterVersioning]) {
		OFString *ver =
		    [[rosterElement attributeForName: @"ver"] stringValue];
		[dataStorage setStringValue: ver
				    forPath: @"roster.ver"];
		[dataStorage save];
	}

	[connection_ sendStanza: [iq resultIQ]];

	return YES;
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

- (void)addDelegate: (id <XMPPRosterDelegate>)delegate
{
	[delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPRosterDelegate>)delegate
{
	[delegates removeDelegate: delegate];
}

- (void)setDataStorage: (id <XMPPStorage>)dataStorage_
{
	if (rosterRequested)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]];

	dataStorage = dataStorage_;
}

- (XMPPConnection*)connection
{
	return connection;
}

- (id <XMPPStorage>)dataStorage
{
	return dataStorage;
}

- (void)XMPP_updateRosterItem: (XMPPRosterItem*)rosterItem
{
	if ([connection supportsRosterVersioning]) {
		OFMutableDictionary *items = [[[dataStorage dictionaryForPath:
		    @"roster.items"] mutableCopy] autorelease];

		if (items == nil)
			items = [OFMutableDictionary dictionary];

		if (![[rosterItem subscription] isEqual: @"remove"]) {
			OFMutableDictionary *item = [OFMutableDictionary
			    dictionaryWithKeysAndObjects:
			    @"JID", [[rosterItem JID] bareJID],
			    @"subscription", [rosterItem subscription],
			    nil];

			if ([rosterItem name] != nil)
				[item setObject: [rosterItem name]
					 forKey: @"name"];

			if ([rosterItem groups] != nil)
				[item setObject: [rosterItem groups]
					 forKey: @"groups"];

			[items setObject: item
				  forKey: [[rosterItem JID] bareJID]];
		} else
			[items removeObjectForKey: [[rosterItem JID] bareJID]];

		[dataStorage setDictionary: items
				   forPath: @"roster.items"];
	}

	if (![[rosterItem subscription] isEqual: @"remove"])
		[rosterItems setObject: rosterItem
				forKey: [[rosterItem JID] bareJID]];
	else
		[rosterItems removeObjectForKey: [[rosterItem JID] bareJID]];
}

- (XMPPRosterItem*)XMPP_rosterItemWithXMLElement: (OFXMLElement*)element
{
	OFString *subscription;
	OFEnumerator *groupEnumerator;
	OFXMLElement *groupElement;
	OFMutableArray *groups = [OFMutableArray array];
	XMPPRosterItem *rosterItem = [XMPPRosterItem rosterItem];
	[rosterItem setJID: [XMPPJID JIDWithString:
	    [[element attributeForName: @"jid"] stringValue]]];
	[rosterItem setName:
	    [[element attributeForName: @"name"] stringValue]];

	subscription = [[element attributeForName:
	    @"subscription"] stringValue];

	if (![subscription isEqual: @"none"] &&
	    ![subscription isEqual: @"to"] &&
	    ![subscription isEqual: @"from"] &&
	    ![subscription isEqual: @"both"] &&
	    ![subscription isEqual: @"remove"])
		subscription = @"none";

	[rosterItem setSubscription: subscription];

	groupEnumerator = [[element
	    elementsForName: @"group"
		  namespace: XMPP_NS_ROSTER] objectEnumerator];
	while ((groupElement = [groupEnumerator nextObject]) != nil)
		[groups addObject: [groupElement stringValue]];

	if ([groups count] > 0)
		[rosterItem setGroups: groups];

	return rosterItem;
}

- (void)XMPP_handleInitialRosterForConnection: (XMPPConnection*)connection_
					   IQ: (XMPPIQ*)iq
{
	OFXMLElement *rosterElement;
	OFEnumerator *enumerator;
	OFXMLElement *element;
	XMPPRosterItem *rosterItem;

	rosterElement = [iq elementForName: @"query"
				 namespace: XMPP_NS_ROSTER];

	if ([connection supportsRosterVersioning] && rosterElement == nil) {
		OFDictionary *items = [dataStorage
		    dictionaryForPath: @"roster.items"];
		OFEnumerator *enumerator = [items objectEnumerator];
		OFDictionary *item;

		while ((item = [enumerator nextObject]) != nil) {
			rosterItem = [XMPPRosterItem rosterItem];
			[rosterItem setJID: [XMPPJID JIDWithString:
			    [item objectForKey: @"JID"]]];
			[rosterItem setName: [item objectForKey: @"name"]];
			[rosterItem setSubscription:
			    [item objectForKey: @"subscription"]];
			[rosterItem setGroups: [item objectForKey: @"groups"]];

			[rosterItems setObject: rosterItem
					forKey: [[rosterItem JID] bareJID]];
		}
	}

	enumerator = [[rosterElement children] objectEnumerator];
	while ((element = [enumerator nextObject]) != nil) {
		if (![[element name] isEqual: @"item"] ||
		    ![[element namespace] isEqual: XMPP_NS_ROSTER])
			continue;

		rosterItem = [self XMPP_rosterItemWithXMLElement: element];

		[self XMPP_updateRosterItem: rosterItem];
	}

	if ([connection supportsRosterVersioning]) {
		OFString *ver =
		    [[rosterElement attributeForName: @"ver"] stringValue];
		[dataStorage setStringValue: ver
				    forPath: @"roster.ver"];
		[dataStorage save];
	}

	[delegates broadcastSelector: @selector(rosterWasReceived:)
			  withObject: self];
}
@end
