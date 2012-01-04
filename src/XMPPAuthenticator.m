/*
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "XMPPAuthenticator.h"

@implementation XMPPAuthenticator
- initWithAuthcid: (OFString*)authcid_
	 password: (OFString*)password_
{
	return [self initWithAuthzid: nil
			     authcid: authcid_
			    password: password_];
}

- initWithAuthzid: (OFString*)authzid_
	  authcid: (OFString*)authcid_
	 password: (OFString*)password_
{
	self = [super init];

	@try {
		authzid = [authzid_ copy];
		authcid = [authcid_ copy];
		password = [password_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[authzid release];
	[authcid release];
	[password release];

	[super dealloc];
}

- (void)setAuthzid: (OFString*)authzid_
{
	OF_SETTER(authzid, authzid_, YES, YES)
}

- (OFString*)authzid
{
	OF_GETTER(authzid, YES)
}

- (void)setAuthcid: (OFString*)authcid_
{
	OF_SETTER(authcid, authcid_, YES, YES)
}

- (OFString*)authcid
{
	OF_GETTER(authcid, YES)
}

- (void)setPassword: (OFString*)password_
{
	OF_SETTER(password, password_, YES, YES)
}

- (OFString*)password
{
	OF_GETTER(password, YES)
}

- (OFDataArray*)initialMessage
{
	return nil;
}

- (OFDataArray*)continueWithData: (OFDataArray*)challenge
{
	return nil;
}
@end
