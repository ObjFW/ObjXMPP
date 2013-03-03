/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#include <string.h>

#include <stringprep.h>

#import "XMPPJID.h"
#import "XMPPExceptions.h"

@implementation XMPPJID
+ JID
{
	return [[[self alloc] init] autorelease];
}

+ JIDWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	size_t nodesep, resourcesep;

	self = [super init];

	if (string == nil) {
		[self release];
		return nil;
	}

	nodesep = [string rangeOfString: @"@"].location;
	resourcesep = [string rangeOfString: @"/"].location;

	if (nodesep == SIZE_MAX)
		[self setNode: nil];
	else
		[self setNode:
		    [string substringWithRange: of_range(0, nodesep)]];

	if (resourcesep == SIZE_MAX) {
		[self setResource: nil];
		resourcesep = [string length];
	} else {
		of_range_t range = of_range(resourcesep + 1,
		    [string length] - resourcesep - 1);
		[self setResource: [string substringWithRange: range]];
	}

	[self setDomain: [string substringWithRange:
	    of_range(nodesep + 1, resourcesep - nodesep - 1)]];

	return self;
}

- (void)dealloc
{
	[_node release];
	[_domain release];
	[_resource release];

	[super dealloc];
}

- copy
{
	XMPPJID *new = [[XMPPJID alloc] init];

	@try {
		new->_node = [_node copy];
		new->_domain = [_domain copy];
		new->_resource = [_resource copy];
	} @catch (id e) {
		[new release];
		@throw e;
	}

	return new;
}

- (void)setNode: (OFString*)node
{
	OFString *old = _node;
	char *nodepart;
	Stringprep_rc rc;

	if (node == nil) {
		[old release];
		_node = nil;
		return;
	}

	if (((rc = stringprep_profile([node UTF8String], &nodepart,
	    "Nodeprep", 0)) != STRINGPREP_OK) || (nodepart[0] == '\0') ||
	    (strlen(nodepart) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Nodeprep"
				string: node];

	@try {
		_node = [[OFString alloc] initWithUTF8String: nodepart];
	} @finally {
		free(nodepart);
	}

	[old release];
}

- (OFString*)node
{
	return [[_node copy] autorelease];
}

- (void)setDomain: (OFString*)domain
{
	OFString *old = _domain;
	char *srv;
	Stringprep_rc rc;

	if (((rc = stringprep_profile([domain UTF8String], &srv,
	    "Nameprep", 0)) != STRINGPREP_OK) || (srv[0] == '\0') ||
	    (strlen(srv) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Nameprep"
				string: domain];

	@try {
		_domain = [[OFString alloc] initWithUTF8String: srv];
	} @finally {
		free(srv);
	}

	[old release];
}

- (OFString*)domain
{
	return [[_domain copy] autorelease];
}

- (void)setResource: (OFString*)resource
{
	OFString *old = _resource;
	char *res;
	Stringprep_rc rc;

	if (resource == nil) {
		[old release];
		_resource = nil;
		return;
	}

	if (((rc = stringprep_profile([resource UTF8String], &res,
	    "Resourceprep", 0)) != STRINGPREP_OK) || (res[0] == '\0') ||
	    (strlen(res) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: [self class]
			    connection: nil
			       profile: @"Resourceprep"
				string: resource];

	@try {
		_resource = [[OFString alloc] initWithUTF8String: res];
	} @finally {
		free(res);
	}

	[old release];
}

- (OFString*)resource
{
	return [[_resource copy] autorelease];
}

- (OFString*)bareJID
{
	if (_node != nil)
		return [OFString stringWithFormat: @"%@@%@", _node, _domain];
	else
		return [OFString stringWithFormat: @"%@", _domain];
}

- (OFString*)fullJID
{
	/* If we don't have a resource, the full JID is equal to the bare JID */
	if (_resource == nil)
		return [self bareJID];

	if (_node != nil)
		return [OFString stringWithFormat: @"%@@%@/%@",
		       _node, _domain, _resource];
	else
		return [OFString stringWithFormat: @"%@/%@",
		       _domain, _resource];
}

- (OFString*)description
{
	return [self fullJID];
}

- (BOOL)isEqual: (id)object
{
	XMPPJID *JID;

	if (object == self)
		return YES;

	if (![object isKindOfClass: [XMPPJID class]])
		return NO;

	JID = object;

	// Node and resource may be nil
	if ((_node == JID->_node || [_node isEqual: JID->_node]) &&
	    [_domain isEqual: JID->_domain] &&
	    (_resource == JID->_resource || [_resource isEqual: JID->_resource])
	   )
		return YES;

	return NO;
}

- (uint32_t) hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_node hash]);
	OF_HASH_ADD_HASH(hash, [_domain hash]);
	OF_HASH_ADD_HASH(hash, [_resource hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end
