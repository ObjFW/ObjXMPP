/*
 * Copyright (c) 2011, 2012, 2013, 2019, 2021, 2025,
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, 2013, Florian Zeitz <florob@babelmonkeys.de>
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

#include <string.h>

#include <stringprep.h>

#import "XMPPJID.h"
#import "XMPPExceptions.h"

@implementation XMPPJID
@synthesize node = _node, domain = _domain, resource = _resource;

+ (instancetype)JID
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)JIDWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		size_t nodesep, resourcesep;

		if (string == nil)
			@throw [OFInvalidArgumentException exception];

		nodesep = [string rangeOfString: @"@"].location;
		resourcesep = [string rangeOfString: @"/"].location;

		if (nodesep == SIZE_MAX)
			self.node = nil;
		else
			self.node = [string substringWithRange:
			    OFRangeMake(0, nodesep)];

		if (resourcesep == SIZE_MAX) {
			self.resource = nil;
			resourcesep = string.length;
		} else {
			OFRange range = OFRangeMake(resourcesep + 1,
			    string.length - resourcesep - 1);
			self.resource = [string substringWithRange: range];
		}

		self.domain = [string substringWithRange:
		    OFRangeMake(nodesep + 1, resourcesep - nodesep - 1)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

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

- (void)setNode: (OFString *)node
{
	OFString *old = _node;
	char *nodepart;
	Stringprep_rc rc;

	if (node == nil) {
		[old release];
		_node = nil;
		return;
	}

	if (((rc = stringprep_profile(node.UTF8String, &nodepart,
	    "Nodeprep", 0)) != STRINGPREP_OK) || (nodepart[0] == '\0') ||
	    (strlen(nodepart) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithConnection: nil
				    profile: @"Nodeprep"
				     string: node];

	@try {
		_node = [[OFString alloc] initWithUTF8StringNoCopy: nodepart
						      freeWhenDone: true];
	} @catch (id e) {
		free(nodepart);
	}

	[old release];
}

- (void)setDomain: (OFString *)domain
{
	OFString *old = _domain;
	char *srv;
	Stringprep_rc rc;

	if (((rc = stringprep_profile(domain.UTF8String, &srv,
	    "Nameprep", 0)) != STRINGPREP_OK) || (srv[0] == '\0') ||
	    (strlen(srv) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithConnection: nil
				    profile: @"Nameprep"
				     string: domain];

	@try {
		_domain = [[OFString alloc] initWithUTF8StringNoCopy: srv
							freeWhenDone: true];
	} @catch (id e) {
		free(srv);
	}

	[old release];
}

- (void)setResource: (OFString *)resource
{
	OFString *old = _resource;
	char *res;
	Stringprep_rc rc;

	if (resource == nil) {
		[old release];
		_resource = nil;
		return;
	}

	if (((rc = stringprep_profile(resource.UTF8String, &res,
	    "Resourceprep", 0)) != STRINGPREP_OK) || (res[0] == '\0') ||
	    (strlen(res) > 1023))
		@throw [XMPPStringPrepFailedException
		    exceptionWithConnection: nil
				    profile: @"Resourceprep"
				     string: resource];

	@try {
		_resource = [[OFString alloc] initWithUTF8StringNoCopy: res
							  freeWhenDone: true];
	} @catch (id e) {
		free(res);
	}

	[old release];
}

- (OFString *)bareJID
{
	if (_node != nil)
		return [OFString stringWithFormat: @"%@@%@", _node, _domain];
	else
		return [OFString stringWithFormat: @"%@", _domain];
}

- (OFString *)fullJID
{
	/* If we don't have a resource, the full JID is equal to the bare JID */
	if (_resource == nil)
		return self.bareJID;

	if (_node != nil)
		return [OFString stringWithFormat: @"%@@%@/%@",
		    _node, _domain, _resource];
	else
		return [OFString stringWithFormat: @"%@/%@",
		    _domain, _resource];
}

- (OFString *)description
{
	return [self fullJID];
}

- (bool)isEqual: (id)object
{
	XMPPJID *JID;

	if (object == self)
		return true;

	if (![object isKindOfClass: [XMPPJID class]])
		return false;

	JID = object;

	// Node and resource may be nil
	if ((_node == JID->_node || [_node isEqual: JID->_node]) &&
	    [_domain isEqual: JID->_domain] && (_resource == JID->_resource ||
	    [_resource isEqual: JID->_resource]))
		return true;

	return false;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _node.hash);
	OFHashAddHash(&hash, _domain.hash);
	OFHashAddHash(&hash, _resource.hash);

	OFHashFinalize(&hash);

	return hash;
}
@end
