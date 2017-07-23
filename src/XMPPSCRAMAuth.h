/*
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import <ObjFW/ObjFW.h>
#import "XMPPAuthenticator.h"
#import "XMPPConnection.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * \brief A class to authenticate using SCRAM
 */
@interface XMPPSCRAMAuth: XMPPAuthenticator
{
	Class _hashType;
	OFString *_cNonce;
	OFString *_GS2Header;
	OFString *_clientFirstMessageBare;
	OFData *_serverSignature;
	XMPPConnection *_connection;
	bool _plusAvailable;
	bool _authenticated;
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
+ (instancetype)SCRAMAuthWithAuthcid: (nullable OFString *)authcid
			    password: (nullable OFString *)password
			  connection: (XMPPConnection *)connection
				hash: (Class)hash
		       plusAvailable: (bool)plusAvailable;

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
+ (instancetype)SCRAMAuthWithAuthzid: (nullable OFString *)authzid
			     authcid: (nullable OFString *)authcid
			    password: (nullable OFString *)password
			  connection: (XMPPConnection *)connection
				hash: (Class)hash
		       plusAvailable: (bool)plusAvailable;

- initWithAuthcid: (nullable OFString *)authcid
	 password: (nullable OFString *)password OF_UNAVAILABLE;
- initWithAuthzid: (nullable OFString *)authzid
	  authcid: (nullable OFString *)authcid
	 password: (nullable OFString *)password OF_UNAVAILABLE;

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
- initWithAuthcid: (nullable OFString *)authcid
	 password: (nullable OFString *)password
       connection: (XMPPConnection *)connection
	     hash: (Class)hash
    plusAvailable: (bool)plusAvailable;

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
- initWithAuthzid: (nullable OFString *)authzid
	  authcid: (nullable OFString *)authcid
	 password: (nullable OFString *)password
       connection: (XMPPConnection *)connection
	     hash: (Class)hash
    plusAvailable: (bool)plusAvailable OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
