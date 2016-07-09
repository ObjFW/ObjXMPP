/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@heap.zone>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://heap.zone/git/?p=objxmpp.git
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
@synthesize connection = _connection, dataStorage = _dataStorage;
@synthesize rosterItems = _rosterItems;

- initWithConnection: (XMPPConnection*)connection
{
	self = [super init];

	@try {
		_rosterItems = [[OFMutableDictionary alloc] init];
		_connection = connection;
		[_connection addDelegate: self];
		_delegates = [[XMPPMulticastDelegate alloc] init];
		_dataStorage = [_connection dataStorage];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_connection removeDelegate: self];
	[_delegates release];
	[_rosterItems release];

	[super dealloc];
}

- (void)requestRoster
{
	XMPPIQ *iq;
	OFXMLElement *query;

	_rosterRequested = true;

	iq = [XMPPIQ IQWithType: @"get"
			     ID: [_connection generateStanzaID]];

	query = [OFXMLElement elementWithName: @"query"
				    namespace: XMPP_NS_ROSTER];

	if ([_connection supportsRosterVersioning]) {
		OFString *ver =
		    [_dataStorage stringValueForPath: @"roster.ver"];

		if (ver == nil)
			ver = @"";

		[query addAttributeWithName: @"ver"
				stringValue: ver];
	}

	[iq addChild: query];

	[_connection sendIQ: iq
	     callbackTarget: self
		   selector: @selector(XMPP_handleInitialRosterForConnection:
				IQ:)];
}

- (bool)connection: (XMPPConnection*)connection
      didReceiveIQ: (XMPPIQ*)iq
{
	OFXMLElement *rosterElement;
	OFXMLElement *element;
	XMPPRosterItem *rosterItem;
	OFString *origin;

	rosterElement = [iq elementForName: @"query"
				 namespace: XMPP_NS_ROSTER];

	if (rosterElement == nil)
		return false;

	if (![[iq type] isEqual: @"set"])
		return false;

	// Ensure the roster push has been sent by the server
	origin = [[iq from] fullJID];
	if (origin != nil && ![origin isEqual: [[connection JID] bareJID]])
		return false;

	element = [rosterElement elementForName: @"item"
				      namespace: XMPP_NS_ROSTER];

	if (element != nil) {
		rosterItem = [self XMPP_rosterItemWithXMLElement: element];

		[_delegates broadcastSelector: @selector(
						   roster:didReceiveRosterItem:)
				   withObject: self
				   withObject: rosterItem];

		[self XMPP_updateRosterItem: rosterItem];
	}

	if ([_connection supportsRosterVersioning]) {
		OFString *ver =
		    [[rosterElement attributeForName: @"ver"] stringValue];
		[_dataStorage setStringValue: ver
				     forPath: @"roster.ver"];
		[_dataStorage save];
	}

	[connection sendStanza: [iq resultIQ]];

	return true;
}

- (void)addRosterItem: (XMPPRosterItem*)rosterItem
{
	[self updateRosterItem: rosterItem];
}

- (void)updateRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set"
				     ID: [_connection generateStanzaID]];
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
	[IQ addChild: query];

	[_connection sendStanza: IQ];
}

- (void)deleteRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set"
				     ID: [_connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPP_NS_ROSTER];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPP_NS_ROSTER];

	[item addAttributeWithName: @"jid"
		       stringValue: [[rosterItem JID] bareJID]];
	[item addAttributeWithName: @"subscription"
		       stringValue: @"remove"];

	[query addChild: item];
	[IQ addChild: query];

	[_connection sendStanza: IQ];
}

- (void)addDelegate: (id <XMPPRosterDelegate>)delegate
{
	[_delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPRosterDelegate>)delegate
{
	[_delegates removeDelegate: delegate];
}

- (void)setDataStorage: (id <XMPPStorage>)dataStorage
{
	if (_rosterRequested)
		/* FIXME: Find a better exception! */
		@throw [OFInvalidArgumentException exception];

	_dataStorage = dataStorage;
}

- (XMPPConnection*)connection
{
	return _connection;
}

- (id <XMPPStorage>)dataStorage
{
	return _dataStorage;
}

- (void)XMPP_updateRosterItem: (XMPPRosterItem*)rosterItem
{
	if ([_connection supportsRosterVersioning]) {
		OFMutableDictionary *items = [[[_dataStorage dictionaryForPath:
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

		[_dataStorage setDictionary: items
				    forPath: @"roster.items"];
	}

	if (![[rosterItem subscription] isEqual: @"remove"])
		[_rosterItems setObject: rosterItem
				 forKey: [[rosterItem JID] bareJID]];
	else
		[_rosterItems removeObjectForKey: [[rosterItem JID] bareJID]];
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

- (void)XMPP_handleInitialRosterForConnection: (XMPPConnection*)connection
					   IQ: (XMPPIQ*)IQ
{
	OFXMLElement *rosterElement;
	OFEnumerator *enumerator;
	OFXMLElement *element;

	rosterElement = [IQ elementForName: @"query"
				 namespace: XMPP_NS_ROSTER];

	if ([connection supportsRosterVersioning]) {
		if (rosterElement == nil) {
			OFDictionary *items = [_dataStorage
			    dictionaryForPath: @"roster.items"];
			OFEnumerator *enumerator = [items objectEnumerator];
			OFDictionary *item;

			while ((item = [enumerator nextObject]) != nil) {
				XMPPRosterItem *rosterItem;
				XMPPJID *JID;

				rosterItem = [XMPPRosterItem rosterItem];
				JID = [XMPPJID JIDWithString:
					  [item objectForKey: @"JID"]];
				[rosterItem setJID: JID];
				[rosterItem setName:
				    [item objectForKey: @"name"]];
				[rosterItem setSubscription:
				    [item objectForKey: @"subscription"]];
				[rosterItem setGroups:
				    [item objectForKey: @"groups"]];

				[_rosterItems setObject: rosterItem
						 forKey: [JID bareJID]];
			}
		} else
			[_dataStorage setDictionary: nil
					    forPath: @"roster.items"];
	}

	enumerator = [[rosterElement children] objectEnumerator];
	while ((element = [enumerator nextObject]) != nil) {
		OFAutoreleasePool *pool;
		XMPPRosterItem *rosterItem;

		if (![[element name] isEqual: @"item"] ||
		    ![[element namespace] isEqual: XMPP_NS_ROSTER])
			continue;

		pool = [[OFAutoreleasePool alloc] init];
		rosterItem = [self XMPP_rosterItemWithXMLElement: element];

		[self XMPP_updateRosterItem: rosterItem];
		[pool release];
	}

	if ([connection supportsRosterVersioning] && rosterElement != nil) {
		OFString *ver =
		    [[rosterElement attributeForName: @"ver"] stringValue];
		[_dataStorage setStringValue: ver
				     forPath: @"roster.ver"];
		[_dataStorage save];
	}

	[_delegates broadcastSelector: @selector(rosterWasReceived:)
			   withObject: self];
}
@end
