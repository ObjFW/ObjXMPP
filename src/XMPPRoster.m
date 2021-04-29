/*
 * Copyright (c) 2011, 2012, 2013, 2016, 2019, 2021,
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
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

OF_ASSUME_NONNULL_BEGIN

@interface XMPPRoster ()
- (void)xmpp_updateRosterItem: (XMPPRosterItem *)rosterItem;
- (void)xmpp_handleInitialRosterForConnection: (XMPPConnection *)connection
					   IQ: (XMPPIQ *)IQ;
- (XMPPRosterItem *)xmpp_rosterItemWithXMLElement: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END

@implementation XMPPRoster
@synthesize connection = _connection, dataStorage = _dataStorage;
@synthesize rosterItems = _rosterItems;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithConnection: (XMPPConnection *)connection
{
	self = [super init];

	@try {
		_rosterItems = [[OFMutableDictionary alloc] init];
		_connection = connection;
		[_connection addDelegate: self];
		_delegates = [[XMPPMulticastDelegate alloc] init];
		_dataStorage = _connection.dataStorage;
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
	XMPPIQ *IQ;
	OFXMLElement *query;

	_rosterRequested = true;

	IQ = [XMPPIQ IQWithType: @"get" ID: [_connection generateStanzaID]];

	query = [OFXMLElement elementWithName: @"query"
				    namespace: XMPPRosterNS];

	if (_connection.supportsRosterVersioning) {
		OFString *ver =
		    [_dataStorage stringValueForPath: @"roster.ver"];

		if (ver == nil)
			ver = @"";

		[query addAttributeWithName: @"ver" stringValue: ver];
	}

	[IQ addChild: query];

	[_connection sendIQ: IQ
	     callbackTarget: self
		   selector: @selector(xmpp_handleInitialRosterForConnection:
				IQ:)];
}

- (bool)connection: (XMPPConnection *)connection didReceiveIQ: (XMPPIQ *)IQ
{
	OFXMLElement *rosterElement;
	OFXMLElement *element;
	XMPPRosterItem *rosterItem;
	OFString *origin;

	rosterElement = [IQ elementForName: @"query" namespace: XMPPRosterNS];

	if (rosterElement == nil)
		return false;

	if (![IQ.type isEqual: @"set"])
		return false;

	// Ensure the roster push has been sent by the server
	origin = IQ.from.fullJID;
	if (origin != nil && ![origin isEqual: connection.JID.bareJID])
		return false;

	element = [rosterElement elementForName: @"item"
				      namespace: XMPPRosterNS];

	if (element != nil) {
		rosterItem = [self xmpp_rosterItemWithXMLElement: element];

		[_delegates broadcastSelector: @selector(
						   roster:didReceiveRosterItem:)
				   withObject: self
				   withObject: rosterItem];

		[self xmpp_updateRosterItem: rosterItem];
	}

	if (_connection.supportsRosterVersioning) {
		OFString *ver =
		    [rosterElement attributeForName: @"ver"].stringValue;
		[_dataStorage setStringValue: ver forPath: @"roster.ver"];
		[_dataStorage save];
	}

	[connection sendStanza: [IQ resultIQ]];

	return true;
}

- (void)addRosterItem: (XMPPRosterItem *)rosterItem
{
	[self updateRosterItem: rosterItem];
}

- (void)updateRosterItem: (XMPPRosterItem *)rosterItem
{
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set"
				     ID: [_connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPPRosterNS];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPPRosterNS];

	[item addAttributeWithName: @"jid" stringValue: rosterItem.JID.bareJID];
	if (rosterItem.name != nil)
		[item addAttributeWithName: @"name"
			       stringValue: rosterItem.name];

	for (OFString *group in rosterItem.groups)
		[item addChild: [OFXMLElement elementWithName: @"group"
						    namespace: XMPPRosterNS
						  stringValue: group]];

	[query addChild: item];
	[IQ addChild: query];

	[_connection sendStanza: IQ];
}

- (void)deleteRosterItem: (XMPPRosterItem *)rosterItem
{
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set"
				     ID: [_connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPPRosterNS];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPPRosterNS];

	[item addAttributeWithName: @"jid" stringValue: rosterItem.JID.bareJID];
	[item addAttributeWithName: @"subscription" stringValue: @"remove"];

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

- (void)xmpp_updateRosterItem: (XMPPRosterItem *)rosterItem
{
	if (_connection.supportsRosterVersioning) {
		OFMutableDictionary *items = [[[_dataStorage dictionaryForPath:
		    @"roster.items"] mutableCopy] autorelease];

		if (items == nil)
			items = [OFMutableDictionary dictionary];

		if (![rosterItem.subscription isEqual: @"remove"]) {
			OFMutableDictionary *item = [OFMutableDictionary
			    dictionaryWithKeysAndObjects:
			    @"JID", rosterItem.JID.bareJID,
			    @"subscription", rosterItem.subscription,
			    nil];

			if (rosterItem.name != nil)
				[item setObject: rosterItem.name
					 forKey: @"name"];

			if ([rosterItem groups] != nil)
				[item setObject: rosterItem.groups
					 forKey: @"groups"];

			[items setObject: item forKey: rosterItem.JID.bareJID];
		} else
			[items removeObjectForKey: rosterItem.JID.bareJID];

		[_dataStorage setDictionary: items forPath: @"roster.items"];
	}

	if (![rosterItem.subscription isEqual: @"remove"])
		[_rosterItems setObject: rosterItem
				 forKey: rosterItem.JID.bareJID];
	else
		[_rosterItems removeObjectForKey: rosterItem.JID.bareJID];
}

- (XMPPRosterItem *)xmpp_rosterItemWithXMLElement: (OFXMLElement *)element
{
	OFString *subscription;
	OFMutableArray *groups = [OFMutableArray array];
	XMPPRosterItem *rosterItem = [XMPPRosterItem rosterItem];
	rosterItem.JID = [XMPPJID JIDWithString:
	    [element attributeForName: @"jid"].stringValue];
	rosterItem.name = [element attributeForName: @"name"].stringValue;

	subscription = [element attributeForName: @"subscription"].stringValue;

	if (![subscription isEqual: @"none"] &&
	    ![subscription isEqual: @"to"] &&
	    ![subscription isEqual: @"from"] &&
	    ![subscription isEqual: @"both"] &&
	    ![subscription isEqual: @"remove"])
		subscription = @"none";

	rosterItem.subscription = subscription;

	for (OFXMLElement *groupElement in
	    [element elementsForName: @"group" namespace: XMPPRosterNS])
		[groups addObject: groupElement.stringValue];

	if (groups.count > 0)
		rosterItem.groups = groups;

	return rosterItem;
}

- (void)xmpp_handleInitialRosterForConnection: (XMPPConnection *)connection
					   IQ: (XMPPIQ *)IQ
{
	OFXMLElement *rosterElement = [IQ elementForName: @"query"
					       namespace: XMPPRosterNS];

	if (connection.supportsRosterVersioning) {
		if (rosterElement == nil) {
			for (OFDictionary *item in
			    [_dataStorage dictionaryForPath: @"roster.items"]) {
				XMPPRosterItem *rosterItem;
				XMPPJID *JID;

				rosterItem = [XMPPRosterItem rosterItem];
				JID = [XMPPJID JIDWithString:
				    [item objectForKey: @"JID"]];
				rosterItem.JID = JID;
				rosterItem.name = [item objectForKey: @"name"];
				rosterItem.subscription =
				    [item objectForKey: @"subscription"];
				rosterItem.groups =
				    [item objectForKey: @"groups"];

				[_rosterItems setObject: rosterItem
						 forKey: JID.bareJID];
			}
		} else
			[_dataStorage setDictionary: nil
					    forPath: @"roster.items"];
	}

	for (OFXMLElement *element in rosterElement.children) {
		void *pool = objc_autoreleasePoolPush();
		XMPPRosterItem *rosterItem;

		if (![element.name isEqual: @"item"] ||
		    ![element.namespace isEqual: XMPPRosterNS])
			continue;

		rosterItem = [self xmpp_rosterItemWithXMLElement: element];

		[self xmpp_updateRosterItem: rosterItem];

		objc_autoreleasePoolPop(pool);
	}

	if (connection.supportsRosterVersioning && rosterElement != nil) {
		OFString *ver =
		    [rosterElement attributeForName: @"ver"].stringValue;
		[_dataStorage setStringValue: ver forPath: @"roster.ver"];
		[_dataStorage save];
	}

	[_delegates broadcastSelector: @selector(rosterWasReceived:)
			   withObject: self];
}
@end
