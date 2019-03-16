/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2013, 2016, 2019, Jonathan Schleifer <js@heap.zone>
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

#import "XMPPDiscoNode.h"
#import "XMPPDiscoNode+Private.h"
#import "XMPPConnection.h"
#import "XMPPIQ.h"
#import "XMPPJID.h"
#import "XMPPDiscoEntity.h"
#import "XMPPDiscoIdentity.h"
#import "namespaces.h"

@implementation XMPPDiscoNode

@synthesize JID = _JID, node = _node, name = _name, identities = _identities;
@synthesize features = _features, childNodes = _childNodes;

+ (instancetype)discoNodeWithJID: (XMPPJID *)JID
			    node: (OFString *)node;
{
	return [[[self alloc] initWithJID: JID
				     node: node] autorelease];
}

+ (instancetype)discoNodeWithJID: (XMPPJID *)JID
			    node: (OFString *)node
			    name: (OFString *)name
{
	return [[[self alloc] initWithJID: JID
				     node: node
				     name: name] autorelease];
}

- (instancetype)initWithJID: (XMPPJID *)JID
		       node: (OFString *)node
{
	return [self initWithJID: JID
			    node: node
			    name: nil];
}

- (instancetype)initWithJID: (XMPPJID *)JID
		       node: (OFString *)node
		       name: (OFString *)name
{
	self = [super init];

	@try {
		if (JID == nil &&
		    ![self isKindOfClass: [XMPPDiscoEntity class]])
			@throw [OFInvalidArgumentException exception];

		_JID = [JID copy];
		_node = [node copy];
		_name = [name copy];
		_identities = [[OFSortedList alloc] init];
		_features = [[OFSortedList alloc] init];
		_childNodes = [[OFMutableDictionary alloc] init];

		[self addFeature: XMPP_NS_DISCO_ITEMS];
		[self addFeature: XMPP_NS_DISCO_INFO];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_JID release];
	[_node release];
	[_name release];
	[_identities release];
	[_features release];
	[_childNodes release];

	[super dealloc];
}

- (OFDictionary *)childNodes
{
	return [[_childNodes copy] autorelease];
}

- (void)addIdentity: (XMPPDiscoIdentity *)identity
{
	[_identities insertObject: identity];
}

- (void)addFeature: (OFString *)feature
{
	[_features insertObject: feature];
}

- (void)addChildNode: (XMPPDiscoNode *)node
{
	[_childNodes setObject: node
			forKey: node.node];
}

- (bool)xmpp_handleItemsIQ: (XMPPIQ *)IQ
		connection: (XMPPConnection *)connection
{
	XMPPIQ *resultIQ;
	OFXMLElement *response;
	OFXMLElement *query = [IQ elementForName: @"query"
				       namespace: XMPP_NS_DISCO_ITEMS];
	OFString *node = [[query attributeForName: @"node"] stringValue];

	if (!(node == _node) && ![node isEqual: _node])
		return false;

	resultIQ = [IQ resultIQ];
	response = [OFXMLElement elementWithName: @"query"
				       namespace: XMPP_NS_DISCO_ITEMS];
	[resultIQ addChild: response];

	for (XMPPDiscoNode *child in _childNodes) {
		OFXMLElement *item =
		    [OFXMLElement elementWithName: @"item"
					namespace: XMPP_NS_DISCO_ITEMS];

		[item addAttributeWithName: @"jid"
			       stringValue: child.JID.fullJID];
		if (child.node != nil)
			[item addAttributeWithName: @"node"
				       stringValue: child.node];
		if (child.name != nil)
			[item addAttributeWithName: @"name"
				       stringValue: child.name];

		[response addChild: item];
	}

	[connection sendStanza: resultIQ];

	return true;
}

- (bool)xmpp_handleInfoIQ: (XMPPIQ *)IQ
	       connection: (XMPPConnection *)connection
{
	XMPPIQ *resultIQ;
	OFXMLElement *response;

	resultIQ = [IQ resultIQ];
	response = [OFXMLElement elementWithName: @"query"
				       namespace: XMPP_NS_DISCO_INFO];
	[resultIQ addChild: response];

	for (XMPPDiscoIdentity *identity in _identities) {
		OFXMLElement *identityElement =
		    [OFXMLElement elementWithName: @"identity"
					namespace: XMPP_NS_DISCO_INFO];

		[identityElement addAttributeWithName: @"category"
					  stringValue: identity.category];
		[identityElement addAttributeWithName: @"type"
					  stringValue: identity.type];
		if (identity.name != nil)
			[identityElement addAttributeWithName: @"name"
						  stringValue: identity.name];

		[response addChild: identityElement];
	}

	for (OFString *feature in _features) {
		OFXMLElement *featureElement =
		    [OFXMLElement elementWithName: @"feature"
					namespace: XMPP_NS_DISCO_INFO];
		[featureElement addAttributeWithName: @"var"
					 stringValue: feature];
		[response addChild: featureElement];
	}

	[connection sendStanza: resultIQ];

	return true;
}
@end
