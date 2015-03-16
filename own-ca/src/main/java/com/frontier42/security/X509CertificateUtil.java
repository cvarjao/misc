package com.frontier42.security;

import java.io.IOException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.SignatureException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;


/**
 * Reference <a href="http://www.java2s.com/Tutorial/Java/0490__Security/CreatingaCertificateinJava.htm">http://www.java2s.com/Tutorial/Java/0490__Security/CreatingaCertificateinJava.htm</a>
 * @author Clécio Varjão
 *
 */
public class X509CertificateUtil {
	public X509Certificate newSelfSignedCert() throws InvalidKeyException, CertificateException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException, IOException{
		X509CertificateInfo info=new X509CertificateInfo();
		return info.generate();
	}
}


