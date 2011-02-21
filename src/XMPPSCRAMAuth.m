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

#include <string.h>
#include <bsd/stdlib.h>
// FIXME: Remove this once libbsd includes arc4random_uniform() in it's headers
#define fake_arc4random_uniform(upper) \
	((uint32_t) (arc4random() / (double) UINT32_MAX * upper))

#import "XMPPSCRAMAuth.h"
#import "XMPPExceptions.h"

#define HMAC_IPAD 0x36
#define HMAC_OPAD 0x5c

@implementation XMPPSCRAMAuth

+ SCRAMAuthWithAuthcid: (OFString*)authcid
	      password: (OFString*)password
		  hash: (Class)hash;
{
	return [[[self alloc] initWithAuthcid: authcid
				     password: password
					 hash: hash] autorelease];
}

+ SCRAMAuthWithAuthzid: (OFString*)authzid
	       authcid: (OFString*)authcid
	      password: (OFString*)password
		  hash: (Class)hash;
{
	return [[[self alloc] initWithAuthzid: authzid
				      authcid: authcid
				     password: password
					 hash: hash] autorelease];
}

- initWithAuthcid: (OFString*)authcid_
	 password: (OFString*)password_
	     hash: (Class)hash;
{
	return [self initWithAuthzid: nil
			     authcid: authcid_
			    password: password_
				hash: hash];
}

- initWithAuthzid: (OFString*)authzid_
	  authcid: (OFString*)authcid_
	 password: (OFString*)password_
	     hash: (Class)hash;
{
	self = [super initWithAuthzid: authzid_
			      authcid: authcid_
			     password: password_];

	hashType = hash;

	return self;
}

- (void)dealloc
{
	[GS2Header release];
	[clientFirstMessageBare release];
	[serverSignature release];
	[cNonce release];

	[super dealloc];
}

- (OFString *)_genNonce
{
	OFMutableString *nonce = [OFMutableString string];
	uint32_t res, i;
	for (i = 0; i < 64; i++) {
		while((res = fake_arc4random_uniform(0x5e) + 0x21) == 0x2C);
		[nonce appendFormat: @"%c", res];
	}

	return nonce;
}

- (uint8_t *)_hmacWithKey: (OFDataArray*)key
		     data: (OFDataArray*)data
{
	size_t i, kSize, blockSize = [hashType blockSize];
	uint8_t *kCArray = NULL, *kI = NULL, *kO = NULL;
	OFAutoreleasePool *pool = nil;
	OFDataArray *k = nil;
	OFHash *hash = nil;

	@try {
		pool = [[OFAutoreleasePool alloc] init];
		k = [OFDataArray dataArrayWithItemSize: 1];
		if (key.itemSize * key.count > blockSize) {
			hash = [[[hashType alloc] init] autorelease];
			[hash updateWithBuffer: [key cArray]
					ofSize: key.itemSize * key.count];
			[k addNItems: [hashType digestSize]
			  fromCArray: [hash digest]];
		} else
			[k addNItems: key.itemSize * key.count
			  fromCArray: [key cArray]];

		kI = [self allocMemoryWithSize: blockSize * sizeof(uint8_t)];
		memset(kI, HMAC_IPAD, blockSize * sizeof(uint8_t));

		kO = [self allocMemoryWithSize: blockSize * sizeof(uint8_t)];
		memset(kO, HMAC_OPAD, blockSize * sizeof(uint8_t));

		kCArray = [k cArray];
		kSize = k.count;
		for (i = 0; i < kSize; i++) {
			kI[i] ^= kCArray[i];
			kO[i] ^= kCArray[i];
		}

		k = [OFDataArray dataArrayWithItemSize: 1];
		[k addNItems: blockSize
		  fromCArray: kI];
		[k addNItems: data.itemSize * data.count
		   fromCArray: [data cArray]];

		hash = [[[hashType alloc] init] autorelease];
		[hash updateWithBuffer: [k cArray]
				ofSize: k.count];
		k = [OFDataArray dataArrayWithItemSize: 1];
		[k addNItems: blockSize
		  fromCArray: kO];
		[k addNItems: [hashType digestSize]
		   fromCArray: [hash digest]];

		hash = [[[hashType alloc] init] autorelease];
		[hash updateWithBuffer: [k cArray]
				ofSize: k.count];

		[hash retain];
		[pool release];
		pool = nil;
		[hash autorelease];

		return [hash digest];
	} @finally {
		[pool release];
		[self freeMemory: kI];
		[self freeMemory: kO];
	}
}

- (OFDataArray *)_hiWithData: (OFDataArray *)str
			salt: (OFDataArray *)salt_
	      iterationCount: (unsigned int)i
{
	uint8_t *result = NULL, *u, *uOld;
	unsigned int j, k;
	size_t digestSize;
	OFAutoreleasePool *pool = nil;
	OFDataArray *salty, *tmp, *ret;

	@try {
		pool = [[OFAutoreleasePool alloc] init];
		digestSize = [hashType digestSize];
		result = [self
		    allocMemoryWithSize: digestSize * sizeof(uint8_t)];
		memset(result, 0, digestSize * sizeof(uint8_t));
		salty = [salt_ copy];
		[salty addNItems: 4
		      fromCArray: "\0\0\0\1"];

		uOld = [self _hmacWithKey: str
				     data: salty];
		[salty release];
		for (j = 0; j < digestSize; j++)
			result[j] ^= uOld[j];

		for (j = 0; j < i-1; j++) {
			tmp = [OFDataArray dataArrayWithItemSize: 1];
			[tmp addNItems: digestSize
			    fromCArray: uOld];
			u = [self _hmacWithKey: str
					  data: tmp];
			for (k = 0; k < digestSize; k++)
				result[k] ^= u[k];
			uOld = u;
		}

		ret = [OFDataArray dataArrayWithItemSize: 1];
		[ret addNItems: digestSize
		    fromCArray: result];

		[ret retain];
		[pool release];
		pool = nil;

		return [ret autorelease];
	} @finally {
		[pool release];
		[self freeMemory: result];
	}
}

- (OFDataArray*)getClientFirstMessage
{
	OFDataArray *ret = [OFDataArray dataArrayWithItemSize: 1];
	[GS2Header release];
	if (authzid)
		GS2Header = [[OFString alloc]
		    initWithFormat: @"n,a=%@,", authzid];
	else
		GS2Header = [[OFString alloc] initWithFormat: @"n,,"];

	[cNonce release];
	cNonce = [[self _genNonce] retain];
	[clientFirstMessageBare release];
	clientFirstMessageBare = [[OFString alloc]
	    initWithFormat: @"n=%@,r=%@", authcid, cNonce];

	[ret addNItems: [GS2Header cStringLength]
	    fromCArray: [GS2Header cString]];

	[ret addNItems: [clientFirstMessageBare cStringLength]
	    fromCArray: [clientFirstMessageBare cString]];

	return ret;
}

- (OFDataArray*)getResponseWithChallenge: (OFDataArray*)challenge
{
	size_t i;
	uint8_t *clientKey, *serverKey, *clientSignature;
	intmax_t iterCount;
	OFHash *hash;
	OFDataArray *ret, *authMessage, *tmpArray, *salt, *saltedPassword;
	OFString *tmpString, *sNonce;
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	@try {
		hash = [[[hashType alloc] init] autorelease];
		ret = [OFDataArray dataArrayWithItemSize: 1];
		authMessage = [OFDataArray dataArrayWithItemSize: 1];

		OFString *chal = [OFString
		    stringWithCString: [challenge cArray]
			       length:
				   [challenge count] * [challenge itemSize]];

		for (OFString *comp
		    in [chal componentsSeparatedByString: @","]) {
			OFString *entry = [comp
			    substringFromIndex: 2
				       toIndex: [comp length]];
			if ([comp hasPrefix: @"r="]) {
				if (![entry hasPrefix: cNonce])
					@throw [XMPPAuthFailedException
					    newWithClass: isa
					      connection: nil
						  reason:
						      @"Received wrong nonce"];
				sNonce = entry;
			} else if ([comp hasPrefix: @"s="])
				salt = [OFDataArray
				    dataArrayWithBase64EncodedString: entry];
			else if ([comp hasPrefix: @"i="])
				iterCount = [entry decimalValue];
		}

		// Add c=<base64(GS2Header+channelBindingData)>
		// XXX: No channel binding for now
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: [GS2Header cStringLength]
			 fromCArray: [GS2Header cString]];
		tmpString = [tmpArray stringByBase64Encoding];
		[ret addNItems: 2
		    fromCArray: "c="];
		[ret addNItems: [tmpString cStringLength]
		    fromCArray: [tmpString cString]];

		// Add r=<nonce>
		[ret addItem: ","];
		[ret addNItems: 2
		    fromCArray: "r="];
		[ret addNItems: [sNonce cStringLength]
		    fromCArray: [sNonce cString]];

		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: [password cStringLength]
			 fromCArray: [password cString]];

		/*
		 * IETF RFC 5802:
		 * SaltedPassword := Hi(Normalize(password), salt, i)
		 */
		saltedPassword = [self _hiWithData: tmpArray
					      salt: salt
				    iterationCount: iterCount];

		/*
		 * IETF RFC 5802:
		 * AuthMessage := client-first-message-bare + "," +
		 *		  server-first-message + "," +
		 *		  client-final-message-without-proof
		 */
		[authMessage addNItems: [clientFirstMessageBare cStringLength]
			    fromCArray: [clientFirstMessageBare cString]];
		[authMessage addItem: ","];
		[authMessage addNItems: [challenge count] * [challenge itemSize]
			    fromCArray: [challenge cArray]];
		[authMessage addItem: ","];
		[authMessage addNItems: [ret count]
			    fromCArray: [ret cArray]];

		/*
		 * IETF RFC 5802:
		 * ClientKey := HMAC(SaltedPassword, "Client Key")
		 */
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: 10
			 fromCArray: "Client Key"];
		clientKey = [self _hmacWithKey: saltedPassword
					  data: tmpArray];

		/*
		 * IETF RFC 5802:
		 * StoredKey := H(ClientKey)
		 */
		[hash updateWithBuffer: (void*) clientKey
				ofSize: [hashType digestSize]];
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: [hashType digestSize]
			 fromCArray: [hash digest]];

		/*
		 * IETF RFC 5802:
		 * ClientSignature := HMAC(StoredKey, AuthMessage)
		 */
		clientSignature = [self _hmacWithKey: tmpArray
						data: authMessage];

		/*
		 * IETF RFC 5802:
		 * ServerKey := HMAC(SaltedPassword, "Server Key")
		 */
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: 10
			 fromCArray: "Server Key"];
		serverKey = [self _hmacWithKey: saltedPassword
					  data: tmpArray];

		/*
		 * IETF RFC 5802:
		 * ServerSignature := HMAC(ServerKey, AuthMessage)
		 */
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		[tmpArray addNItems: [hashType digestSize]
			 fromCArray: serverKey];
		serverSignature = [[OFDataArray alloc] initWithItemSize: 1];
		[serverSignature addNItems: [hashType digestSize]
				fromCArray: [self _hmacWithKey: tmpArray
							  data: authMessage]];

		/*
		 * IETF RFC 5802:
		 * ClientProof := ClientKey XOR ClientSignature
		 */
		tmpArray = [OFDataArray dataArrayWithItemSize: 1];
		for (i = 0; i < [hashType digestSize]; i++) {
			uint8_t c = clientKey[i] ^ clientSignature[i];
			[tmpArray addItem: &c];
		}

		// Add p=<base64(ClientProof)>
		[ret addItem: ","];
		[ret addNItems: 2
		    fromCArray: "p="];
		tmpString = [tmpArray stringByBase64Encoding];
		[ret addNItems: [tmpString cStringLength]
		    fromCArray: [tmpString cString]];

		[ret retain];
		[pool release];
		pool = nil;

		return [ret autorelease];
	} @finally {
		[pool release];
	}
}

- (void)parseServerFinalMessage: (OFDataArray*)message
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	@try {
		OFString *mess = [OFString
		    stringWithCString: [message cArray]
			       length: [message count] * [message itemSize]];

		OFString *value = [mess substringFromIndex: 2
						   toIndex: [mess length]];

		if ([mess hasPrefix: @"v="]) {
			if ([value compare:
			    [serverSignature stringByBase64Encoding]])
				@throw [XMPPAuthFailedException
				    newWithClass: isa
				      connection: nil
					  reason:
					    @"Received wrong ServerSignature"];
		} else
			@throw [XMPPAuthFailedException newWithClass: isa
							  connection: nil
							      reason: value];
	} @finally {
		[pool release];
	}
}
@end
