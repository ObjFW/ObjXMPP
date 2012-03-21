/*
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

#import <ObjFW/ObjFW.h>
#import "XMPPAuthenticator.h"
#import "XMPPConnection.h"

/**
 * \brief A class to authenticate using SCRAM
 */
@interface XMPPSCRAMAuth: XMPPAuthenticator
{
/// \cond internal
	Class hashType;
	OFString *cNonce;
	OFString *GS2Header;
	OFString *clientFirstMessageBare;
	OFDataArray *serverSignature;
	XMPPConnection *connection;
	BOOL plusAvailable;
	BOOL authenticated;
/// \endcond
}

/**
 * \brief Creates a new autoreleased XMPPSCRAMAuth with an authcid and password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param connection The connection over which authentication is done
 * \param hash The class to use for calulating hashes
 * \param plusAvailable Whether the PLUS variant was offered
 * \return A new autoreleased XMPPSCRAMAuth
 */
+ SCRAMAuthWithAuthcid: (OFString*)authcid
	      password: (OFString*)password
	    connection: (XMPPConnection*)connection
		  hash: (Class)hash
	 plusAvailable: (BOOL)plusAvailable;

/**
 * \brief Creates a new autoreleased XMPPSCRAMAuth with an authzid, authcid and
 *	  password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param connection The connection over which authentication is done
 * \param hash The class to use for calulating hashes
 * \param plusAvailable Whether the PLUS variant was offered
 * \return A new autoreleased XMPPSCRAMAuth
 */
+ SCRAMAuthWithAuthzid: (OFString*)authzid
	       authcid: (OFString*)authcid
	      password: (OFString*)password
	    connection: (XMPPConnection*)connection
		  hash: (Class)hash
	 plusAvailable: (BOOL)plusAvailable;

/**
 * \brief Initializes an already allocated XMPPSCRAMAuth with an authcid and
 *	  password.
 *
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param connection The connection over which authentication is done
 * \param hash The class to use for calulating hashes
 * \param plusAvailable Whether the PLUS variant was offered
 * \return A initialized XMPPSCRAMAuth
 */
- initWithAuthcid: (OFString*)authcid
	 password: (OFString*)password
       connection: (XMPPConnection*)connection
	     hash: (Class)hash
    plusAvailable: (BOOL)plusAvailable;

/**
 * \brief Initializes an already allocated XMPPSCRAMAuth with a authzid,
 *	  authcid and password.
 *
 * \param authzid The authzid to get authorization for
 * \param authcid The authcid to authenticate with
 * \param password The password to authenticate with
 * \param connection The connection over which authentication is done
 * \param hash The class to use for calulating hashes
 * \param plusAvailable Whether the PLUS variant was offered
 * \return A initialized XMPPSCRAMAuth
 */
- initWithAuthzid: (OFString*)authzid
	  authcid: (OFString*)authcid
	 password: (OFString*)password
       connection: (XMPPConnection*)connection
	     hash: (Class)hash
    plusAvailable: (BOOL)plusAvailable;

/// \cond internal
- (OFString*)XMPP_genNonce;
- (uint8_t*)XMPP_HMACWithKey: (OFDataArray*)key
			data: (OFDataArray*)data;
- (OFDataArray*)XMPP_hiWithData: (OFDataArray *)str
			   salt: (OFDataArray *)salt_
		 iterationCount: (intmax_t)i;
- (OFDataArray*)XMPP_parseServerFirstMessage: (OFDataArray*)data;
- (OFDataArray*)XMPP_parseServerFinalMessage: (OFDataArray*)data;
/// \endcond
@end
