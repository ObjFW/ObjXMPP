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

#import <ObjFW/ObjFW.h>
#import "XMPPAuthenticator.h"

/**
 * \brief A class to authenticate using SCRAM
 */
@interface XMPPSCRAMAuth: XMPPAuthenticator
{
	Class hashType;
	OFString *cNonce;
	OFString *GS2Header;
	OFString *clientFirstMessageBare;
	OFDataArray *serverSignature;
}

/**
 * Creates a new autoreleased XMPPSCRAMAuth with an authcid and password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param hash The class to use for calulating hashes
 * \return A new autoreleased XMPPSCRAMAuth
 */
+ SCRAMAuthWithAuthcid: (OFString*)authcid
	      password: (OFString*)password
		  hash: (Class)hash;

/**
 * Creates a new autoreleased XMPPSCRAMAuth with an authzid,
 * authcid and password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param hash The class to use for calulating hashes
 * \return A new autoreleased XMPPSCRAMAuth
 */
+ SCRAMAuthWithAuthzid: (OFString*)authzid
	       authcid: (OFString*)authcid
	      password: (OFString*)password
		  hash: (Class)hash;

/**
 * Initializes an already allocated XMPPSCRAMAuth with an authcid and password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param hash The class to use for calulating hashes
 * \return A initialized XMPPSCRAMAuth
 */
- initWithAuthcid: (OFString*)authcid
	 password: (OFString*)password
	     hash: (Class)hash;

/**
 * Initializes an already allocated XMPPSCRAMAuth with a authzid,
 * authcid and password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param hash The class to use for calulating hashes
 * \return A initialized XMPPSCRAMAuth
 */
- initWithAuthzid: (OFString*)authzid
	  authcid: (OFString*)authcid
	 password: (OFString*)password
	     hash: (Class)hash;

- (OFString*)XMPP_genNonce;
- (uint8_t*)XMPP_HMACWithKey: (OFDataArray*)key
			data: (OFDataArray*)data;
- (OFDataArray*)XMPP_hiWithData: (OFDataArray *)str
			   salt: (OFDataArray *)salt_
		 iterationCount: (intmax_t)i;
@end
