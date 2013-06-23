/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPDiscoIdentity.h"

@implementation XMPPDiscoIdentity
+ (instancetype)identityWithCategory: (OFString*)category
				type: (OFString*)type
				name: (OFString*)name
{
	return [[[self alloc] initWithCategory: category
					  type: type
					  name: name] autorelease];
}

+ (instancetype)identityWithCategory: (OFString*)category
				type: (OFString*)type
{
	return [[[self alloc] initWithCategory: category
					  type: type] autorelease];
}

- initWithCategory: (OFString*)category
	      type: (OFString*)type
	      name: (OFString*)name
{
	self = [super init];

	@try {
		if (category == nil || type == nil)
			@throw [OFInvalidArgumentException exception];

		_category = [category copy];
		_name = [name copy];
		_type = [type copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCategory: (OFString*)category
	      type: (OFString*)type
{
	return [self initWithCategory: category
				 type: type
				 name: nil];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- (void)dealloc
{
	[_category release];
	[_name release];
	[_type release];

	[super dealloc];
}

- (OFString*)category
{
	OF_GETTER(_category, true)
}

- (OFString*)name
{
	OF_GETTER(_name, true)
}

- (OFString*)type
{
	OF_GETTER(_type, true)
}

- (bool)isEqual: (id)object
{
	XMPPDiscoIdentity *identity;

	if (object == self)
		return true;

	if (![object isKindOfClass: [XMPPDiscoIdentity class]])
		return false;

	identity = object;

	if ([_category isEqual: identity->_category] &&
	    (_name == identity->_name || [_name isEqual: identity->_name]) &&
	    [_type isEqual: identity->_type])
		return true;

	return false;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_category hash]);
	OF_HASH_ADD_HASH(hash, [_type hash]);
	OF_HASH_ADD_HASH(hash, [_name hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	XMPPDiscoIdentity *identity;
	of_comparison_result_t categoryResult;
	of_comparison_result_t typeResult;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![object isKindOfClass: [XMPPDiscoIdentity class]])
		@throw [OFInvalidArgumentException exception];

	identity = (XMPPDiscoIdentity*)object;

	categoryResult = [_category compare: identity->_category];
	if (categoryResult != OF_ORDERED_SAME)
		return categoryResult;

	typeResult = [_type compare: identity->_type];
	if (typeResult != OF_ORDERED_SAME)
		return typeResult;

	return [_name compare: identity->_name];
}
@end
