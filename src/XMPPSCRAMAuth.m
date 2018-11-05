/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#include "config.h"

#include <string.h>
#include <assert.h>
#include <openssl/rand.h>

#import <ObjOpenSSL/SSLSocket.h>

#import "XMPPSCRAMAuth.h"
#import "XMPPExceptions.h"

#define HMAC_IPAD 0x36
#define HMAC_OPAD 0x5c

@interface XMPPSCRAMAuth ()
- (OFString *)xmpp_genNonce;
- (const uint8_t *)xmpp_HMACWithKey: (OFData *)key
			       data: (OFData *)data;
- (OFData *)xmpp_hiWithData: (OFData *)str
		       salt: (OFData *)salt
	     iterationCount: (intmax_t)i;
- (OFData *)xmpp_parseServerFirstMessage: (OFData *)data;
- (OFData *)xmpp_parseServerFinalMessage: (OFData *)data;
@end

@implementation XMPPSCRAMAuth
+ (instancetype)SCRAMAuthWithAuthcid: (OFString *)authcid
			    password: (OFString *)password
			  connection: (XMPPConnection *)connection
				hash: (Class)hash
		       plusAvailable: (bool)plusAvailable
{
	return [[[self alloc] initWithAuthcid: authcid
				     password: password
				   connection: connection
					 hash: hash
				plusAvailable: plusAvailable] autorelease];
}

+ (instancetype)SCRAMAuthWithAuthzid: (OFString *)authzid
			     authcid: (OFString *)authcid
			    password: (OFString *)password
			  connection: (XMPPConnection *)connection
				hash: (Class)hash
		       plusAvailable: (bool)plusAvailable
{
	return [[[self alloc] initWithAuthzid: authzid
				      authcid: authcid
				     password: password
				   connection: connection
					 hash: hash
				plusAvailable: plusAvailable] autorelease];
}

- (instancetype)initWithAuthcid: (OFString *)authcid
		       password: (OFString *)password
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithAuthzid: (OFString *)authzid
			authcid: (OFString *)authcid
		       password: (OFString *)password
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithAuthcid: (OFString *)authcid
		       password: (OFString *)password
		     connection: (XMPPConnection *)connection
			   hash: (Class)hash
		  plusAvailable: (bool)plusAvailable
{
	return [self initWithAuthzid: nil
			     authcid: authcid
			    password: password
			  connection: connection
				hash: hash
		       plusAvailable: plusAvailable];
}

- (instancetype)initWithAuthzid: (OFString *)authzid
			authcid: (OFString *)authcid
		       password: (OFString *)password
		     connection: (XMPPConnection *)connection
			   hash: (Class)hash
		  plusAvailable: (bool)plusAvailable
{
	self = [super initWithAuthzid: authzid
			      authcid: authcid
			     password: password];

	_hashType = hash;
	_plusAvailable = plusAvailable;
	_connection = [connection retain];

	return self;
}

- (void)dealloc
{
	[_GS2Header release];
	[_clientFirstMessageBare release];
	[_serverSignature release];
	[_cNonce release];
	[_connection release];

	[super dealloc];
}

- (void)setAuthzid: (OFString *)authzid
{
	OFString *old = _authzid;

	if (authzid) {
		OFMutableString *new = [[authzid mutableCopy] autorelease];
		[new replaceOccurrencesOfString: @"="
				     withString: @"=3D"];
		[new replaceOccurrencesOfString: @","
				     withString: @"=2C"];
		_authzid = [new retain];
	} else
		_authzid = nil;

	[old release];
}

- (void)setAuthcid: (OFString *)authcid
{
	OFString *old = _authcid;

	if (authcid) {
		OFMutableString *new = [[authcid mutableCopy] autorelease];
		[new replaceOccurrencesOfString: @"="
				     withString: @"=3D"];
		[new replaceOccurrencesOfString: @","
				     withString: @"=2C"];
		_authcid = [new retain];
	} else
		_authcid = nil;

	[old release];
}

- (OFData *)initialMessage
{
	OFMutableData *ret = [OFMutableData data];

	/* New authentication attempt, reset status */
	[_cNonce release];
	_cNonce = nil;
	[_GS2Header release];
	_GS2Header = nil;
	[_serverSignature release];
	_serverSignature = nil;
	_authenticated = false;

	if (_authzid != nil)
		_GS2Header = [[OFString alloc]
		    initWithFormat: @"%@,a=%@,",
				    (_plusAvailable ? @"p=tls-unique" : @"y"),
				    _authzid];
	else
		_GS2Header = (_plusAvailable ? @"p=tls-unique,," : @"y,,");

	_cNonce = [[self xmpp_genNonce] retain];

	[_clientFirstMessageBare release];
	_clientFirstMessageBare = nil;
	_clientFirstMessageBare = [[OFString alloc]
	    initWithFormat: @"n=%@,r=%@", _authcid, _cNonce];

	[ret addItems: [_GS2Header UTF8String]
		count: [_GS2Header UTF8StringLength]];

	[ret addItems: [_clientFirstMessageBare UTF8String]
		count: [_clientFirstMessageBare UTF8StringLength]];

	[ret makeImmutable];

	return ret;
}

- (OFData *)continueWithData: (OFData *)data
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFData *ret;

	if (!_serverSignature)
		ret = [self xmpp_parseServerFirstMessage: data];
	else
		ret = [self xmpp_parseServerFinalMessage: data];

	[ret retain];
	[pool release];

	return [ret autorelease];
}

- (OFData *)xmpp_parseServerFirstMessage: (OFData *)data
{
	size_t i;
	const uint8_t *clientKey, *serverKey, *clientSignature;
	intmax_t iterCount = 0;
	id <OFCryptoHash> hash;
	OFMutableData *ret, *authMessage, *tmpArray;
	OFData *salt = nil, *saltedPassword;
	OFString *tmpString, *sNonce = nil;
	enum {
		GOT_SNONCE    = 0x01,
		GOT_SALT      = 0x02,
		GOT_ITERCOUNT = 0x04
	} got = 0;

	hash = [[[_hashType alloc] init] autorelease];
	ret = [OFMutableData data];
	authMessage = [OFMutableData data];

	OFString *challenge = [OFString stringWithUTF8String: [data items]
						      length: [data count] *
							      [data itemSize]];

	for (OFString *component in
	    [challenge componentsSeparatedByString: @","]) {
		OFString *entry = [component substringWithRange:
		    of_range(2, [component length] - 2)];

		if ([component hasPrefix: @"r="]) {
			if (![entry hasPrefix: _cNonce])
				@throw [XMPPAuthFailedException
				    exceptionWithConnection: nil
						     reason: @"Received wrong "
							     @"nonce"];

			sNonce = entry;
			got |= GOT_SNONCE;
		} else if ([component hasPrefix: @"s="]) {
			salt = [OFData dataWithBase64EncodedString: entry];
			got |= GOT_SALT;
		} else if ([component hasPrefix: @"i="]) {
			iterCount = [entry decimalValue];
			got |= GOT_ITERCOUNT;
		}
	}

	if (got != (GOT_SNONCE | GOT_SALT | GOT_ITERCOUNT))
		@throw [OFInvalidServerReplyException exception];

	// Add c=<base64(GS2Header+channelBindingData)>
	tmpArray = [OFMutableData dataWithItems: [_GS2Header UTF8String]
					  count: [_GS2Header UTF8StringLength]];
	if (_plusAvailable && [_connection encrypted]) {
		OFData *channelBinding = [((SSLSocket *)[_connection socket])
		    channelBindingDataWithType: @"tls-unique"];
		[tmpArray addItems: [channelBinding items]
			     count: [channelBinding count]];
	}
	tmpString = [tmpArray stringByBase64Encoding];
	[ret addItems: "c="
		count: 2];
	[ret addItems: [tmpString UTF8String]
		count: [tmpString UTF8StringLength]];

	// Add r=<nonce>
	[ret addItem: ","];
	[ret addItems: "r="
		count: 2];
	[ret addItems: [sNonce UTF8String]
		count: [sNonce UTF8StringLength]];

	/*
	 * IETF RFC 5802:
	 * SaltedPassword := Hi(Normalize(password), salt, i)
	 */
	tmpArray = [OFMutableData dataWithItems: [_password UTF8String]
					  count: [_password UTF8StringLength]];
	saltedPassword = [self xmpp_hiWithData: tmpArray
					  salt: salt
				iterationCount: iterCount];

	/*
	 * IETF RFC 5802:
	 * AuthMessage := client-first-message-bare + "," +
	 *		  server-first-message + "," +
	 *		  client-final-message-without-proof
	 */
	[authMessage addItems: [_clientFirstMessageBare UTF8String]
			count: [_clientFirstMessageBare UTF8StringLength]];
	[authMessage addItem: ","];
	[authMessage addItems: [data items]
			count: [data count] * [data itemSize]];
	[authMessage addItem: ","];
	[authMessage addItems: [ret items]
			count: [ret count]];

	/*
	 * IETF RFC 5802:
	 * ClientKey := HMAC(SaltedPassword, "Client Key")
	 */
	clientKey = [self xmpp_HMACWithKey: saltedPassword
				      data: [OFData dataWithItems: "Client Key"
							    count: 10]];

	/*
	 * IETF RFC 5802:
	 * StoredKey := H(ClientKey)
	 */
	[hash updateWithBuffer: (void *)clientKey
			length: [_hashType digestSize]];

	/*
	 * IETF RFC 5802:
	 * ClientSignature := HMAC(StoredKey, AuthMessage)
	 */
	clientSignature = [self
	    xmpp_HMACWithKey: [OFData dataWithItems: [hash digest]
					      count: [_hashType digestSize]]
			data: authMessage];

	/*
	 * IETF RFC 5802:
	 * ServerKey := HMAC(SaltedPassword, "Server Key")
	 */
	serverKey = [self xmpp_HMACWithKey: saltedPassword
				      data: [OFData dataWithItems: "Server Key"
							    count: 10]];

	/*
	 * IETF RFC 5802:
	 * ServerSignature := HMAC(ServerKey, AuthMessage)
	 */
	tmpArray = [OFMutableData dataWithItems: serverKey
					  count: [_hashType digestSize]];

	[_serverSignature release];
	_serverSignature = [[OFData alloc]
	    initWithItems: [self xmpp_HMACWithKey: tmpArray
					     data: authMessage]
		    count: [_hashType digestSize]];

	/*
	 * IETF RFC 5802:
	 * ClientProof := ClientKey XOR ClientSignature
	 */
	tmpArray = [OFMutableData dataWithCapacity: [_hashType digestSize]];
	for (i = 0; i < [_hashType digestSize]; i++) {
		uint8_t c = clientKey[i] ^ clientSignature[i];
		[tmpArray addItem: &c];
	}

	// Add p=<base64(ClientProof)>
	[ret addItem: ","];
	[ret addItems: "p="
		count: 2];
	tmpString = [tmpArray stringByBase64Encoding];
	[ret addItems: [tmpString UTF8String]
		count: [tmpString UTF8StringLength]];

	return ret;
}

- (OFData *)xmpp_parseServerFinalMessage: (OFData *)data
{
	OFString *mess, *value;

	/*
	 * server-final-message already received,
	 * we were just waiting for the last word from the server
	 */
	if (_authenticated)
		return nil;

	mess = [OFString stringWithUTF8String: [data items]
				       length: [data count] * [data itemSize]];
	value = [mess substringWithRange: of_range(2, [mess length] - 2)];

	if ([mess hasPrefix: @"v="]) {
		if (![value isEqual: [_serverSignature stringByBase64Encoding]])
			@throw [XMPPAuthFailedException
			    exceptionWithConnection: nil
					     reason: @"Received wrong "
						     @"ServerSignature"];
		_authenticated = true;
	} else
		@throw [XMPPAuthFailedException exceptionWithConnection: nil
								 reason: value];

	return nil;
}

- (OFString *)xmpp_genNonce
{
	uint8_t buf[64];
	size_t i;

	assert(RAND_pseudo_bytes(buf, 64) >= 0);

	for (i = 0; i < 64; i++) {
		// Restrict salt to printable range, but do not include '~'...
		buf[i] = (buf[i] % ('~' - '!')) + '!';

		// ...so we can use it to replace ','
		if (buf[i] == ',')
			buf[i] = '~';
	}

	return [OFString stringWithCString: (char *)buf
				  encoding: OF_STRING_ENCODING_ASCII
				    length: 64];
}

- (const uint8_t *)xmpp_HMACWithKey: (OFData *)key
			       data: (OFData *)data
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *k = [OFMutableData data];
	size_t i, kSize, blockSize = [_hashType blockSize];
	uint8_t *kI = NULL, *kO = NULL;
	id <OFCryptoHash> hashI, hashO;

	if ([key itemSize] * [key count] > blockSize) {
		hashI = [[[_hashType alloc] init] autorelease];
		[hashI updateWithBuffer: [key items]
				length: [key itemSize] * [key count]];
		[k addItems: [hashI digest]
		      count: [_hashType digestSize]];
	} else
		[k addItems: [key items]
		      count: [key itemSize] * [key count]];

	@try {
		kI = [self allocMemoryWithSize: blockSize];
		kO = [self allocMemoryWithSize: blockSize];

		kSize = [k count];
		memcpy(kI, [k items], kSize);
		memset(kI + kSize, 0, blockSize - kSize);
		memcpy(kO, kI, blockSize);

		for (i = 0; i < blockSize; i++) {
			kI[i] ^= HMAC_IPAD;
			kO[i] ^= HMAC_OPAD;
		}

		hashI = [[[_hashType alloc] init] autorelease];
		[hashI updateWithBuffer: (char *)kI
				 length: blockSize];
		[hashI updateWithBuffer: [data items]
				 length: [data itemSize] * [data count]];

		hashO = [[[_hashType alloc] init] autorelease];
		[hashO updateWithBuffer: (char *)kO
				 length: blockSize];
		[hashO updateWithBuffer: (char *)[hashI digest]
				 length: [_hashType digestSize]];
	} @finally {
		[self freeMemory: kI];
		[self freeMemory: kO];
	}

	[hashO retain];

	objc_autoreleasePoolPop(pool);

	return [[hashO autorelease] digest];
}

- (OFData *)xmpp_hiWithData: (OFData *)str
		       salt: (OFData *)salt
	     iterationCount: (intmax_t)i
{
	void *pool = objc_autoreleasePoolPush();
	size_t digestSize = [_hashType digestSize];
	uint8_t *result = NULL;
	const uint8_t *u, *uOld;
	intmax_t j, k;
	OFMutableData *salty, *tmp;
	OFData *ret;

	result = [self allocMemoryWithSize: digestSize];

	@try {
		memset(result, 0, digestSize);

		salty = [[salt mutableCopy] autorelease];
		[salty addItems: "\0\0\0\1"
			  count: 4];

		uOld = [self xmpp_HMACWithKey: str
					 data: salty];

		for (j = 0; j < digestSize; j++)
			result[j] ^= uOld[j];

		for (j = 0; j < i - 1; j++) {
			tmp = [[OFMutableData alloc] init];
			[tmp addItems: uOld
				count: digestSize];

			/* releases uOld and previous tmp */
			objc_autoreleasePoolPop(pool);
			pool = objc_autoreleasePoolPush();
			[tmp autorelease];

			u = [self xmpp_HMACWithKey: str
					      data: tmp];

			for (k = 0; k < digestSize; k++)
				result[k] ^= u[k];

			uOld = u;
		}

		ret = [OFData dataWithItems: result
				      count: digestSize];
	} @finally {
		[self freeMemory: result];
	}

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
