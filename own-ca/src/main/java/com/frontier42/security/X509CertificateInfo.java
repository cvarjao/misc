package com.frontier42.security;

import java.io.FileOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.SignatureException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Calendar;
import java.util.Date;
import java.util.Hashtable;
import java.util.Map;
import java.util.Map.Entry;

import sun.security.x509.AlgorithmId;
import sun.security.x509.CertificateAlgorithmId;
import sun.security.x509.CertificateIssuerName;
import sun.security.x509.CertificateSerialNumber;
import sun.security.x509.CertificateSubjectName;
import sun.security.x509.CertificateValidity;
import sun.security.x509.CertificateVersion;
import sun.security.x509.CertificateX509Key;
import sun.security.x509.X500Name;
import sun.security.x509.X509CertImpl;
import sun.security.x509.X509CertInfo;

@SuppressWarnings("restriction")
public class X509CertificateInfo {
	public static final String SIGN_ALGO_SHA1WITHRSA="SHA1withRSA";
	public static final String SIGN_ALGO_MD5WITHRSA="MD5WithRSA";
	private static final String SUBJECT=".subject-dn";
	private static final String ALGORITHM=".algorithm";
	private static final String PRIVATE_KEY=".privateKey";
	
	private Map<String, Object> info = new Hashtable<String, Object>();
	public X509CertificateInfo() {
	}
	
	private Map<String, Object> putDefaults(Map<String, Object> map) throws CertificateException, IOException{
		if (!map.containsKey(X509CertInfo.SERIAL_NUMBER)){
			map.put(X509CertInfo.SERIAL_NUMBER, new CertificateSerialNumber(new BigInteger(64, new SecureRandom())));
		}
		if (!map.containsKey(X509CertInfo.VERSION)){
			map.put(X509CertInfo.VERSION, new CertificateVersion(CertificateVersion.V3));
		}
		return map;
	}
	public void setAlgorithm(String name){
		info.put(ALGORITHM, name);
	}
	public void setSubject(String dn){
		info.put(SUBJECT, dn);
	}
	public void setPublicKey(PublicKey publicKey){
		info.put(X509CertInfo.KEY, new CertificateX509Key(publicKey));
	}
	public void setPrivateKey(PrivateKey privateKey){
		info.put(PRIVATE_KEY, privateKey);
	}
	public void setValidity(Date notBefore, Date notAfter) throws CertificateException, IOException{
		info.put(X509CertInfo.VALIDITY, new CertificateValidity(notBefore, notAfter));
	}

	public X509Certificate generate() throws CertificateException, IOException, InvalidKeyException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException{
		Map<String, Object> map=new Hashtable<String, Object>();
		map.putAll(info);
		putDefaults(map);
		
		if (!map.containsKey(X509CertInfo.VALIDITY)){
			new CertificateException("Missing 'validity'");
		}
		
		if (!map.containsKey(X509CertInfo.KEY)){
			new CertificateException("Missing 'publicKey'");
		}
		
		if (!map.containsKey(SUBJECT)){
			new CertificateException("Missing 'subject'");
		}
		
		if (!map.containsKey(ALGORITHM)){
			new CertificateException("Missing 'algorithm'");
		}
		
		X509CertInfo certInfo = new X509CertInfo();
		
		String dn=(String) map.get(SUBJECT);
		String algoName=(String) map.get(ALGORITHM);
		AlgorithmId algoId=null;
		if (SIGN_ALGO_MD5WITHRSA.equalsIgnoreCase(algoName)){
			algoId=new AlgorithmId(AlgorithmId.md5WithRSAEncryption_oid);
		}else if (SIGN_ALGO_SHA1WITHRSA.equalsIgnoreCase(algoName)){
			algoId=new AlgorithmId(AlgorithmId.sha1WithRSAEncryption_oid);
		}
		X500Name owner=new X500Name(dn);
		
		for(Entry<String, Object> entry:map.entrySet()){
			String key=entry.getKey();
			if (!key.startsWith(".")){
				certInfo.set(key, entry.getValue());
			}
		}
		
		certInfo.set(X509CertInfo.SUBJECT,  new CertificateSubjectName(owner));
		certInfo.set(X509CertInfo.ISSUER, new CertificateIssuerName(owner));
		certInfo.set(X509CertInfo.ALGORITHM_ID, new CertificateAlgorithmId(algoId));
		
		X509CertImpl cert= new X509CertImpl(certInfo);
		cert.sign((PrivateKey)info.get(PRIVATE_KEY), algoName);
		
		 // Update the algorith, and resign.
		algoId = (AlgorithmId)cert.get(X509CertImpl.SIG_ALG);
		certInfo.set(CertificateAlgorithmId.NAME + "." + CertificateAlgorithmId.ALGORITHM, algoId);
		cert = new X509CertImpl(certInfo);
		cert.sign((PrivateKey)info.get(PRIVATE_KEY), algoName);
		  
		return cert;
	}
	public static KeyPair newKeyPair(String algorithm, SecureRandom sr) throws NoSuchAlgorithmException{
		KeyPairGenerator keyGen = KeyPairGenerator.getInstance(algorithm);
		keyGen.initialize(1024, sr);
		KeyPair keypair = keyGen.generateKeyPair();
		return keypair;
	}
	public static KeyPair newKeyPair(String algorithm) throws NoSuchAlgorithmException{
		return newKeyPair(algorithm, new SecureRandom());
	}
	public static KeyPair newRSAKeyPair() throws NoSuchAlgorithmException{
		return newKeyPair("RSA");
	}
	public static void sign(X509Certificate cert, PrivateKey privateKey, String algorithm) throws InvalidKeyException, CertificateException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException{
		((X509CertImpl)cert).sign(privateKey, algorithm);
	}
	public static void main(String[] args) throws CertificateException, IOException, NoSuchAlgorithmException, InvalidKeyException, NoSuchProviderException, SignatureException, KeyStoreException {
		KeyPair keyPair=X509CertificateInfo.newRSAKeyPair();
		X509CertificateInfo info=new X509CertificateInfo();
		info.setSubject("CN=localhost");
		Date startDate=new Date();
		Calendar cal = Calendar.getInstance();
		cal.setTime(startDate);
		cal.add(Calendar.HOUR_OF_DAY, 1);
		info.setValidity(startDate, cal.getTime());
		info.setAlgorithm(SIGN_ALGO_MD5WITHRSA);
		info.setPublicKey(keyPair.getPublic());
		info.setPrivateKey(keyPair.getPrivate());
		X509Certificate cert=info.generate();
		char[] certPassword = new char[]{'a','b','c','d','e','f','g','h'};
		
		KeyStore keyStore = KeyStore.getInstance("JKS");
		keyStore.load(null, certPassword);
		keyStore.setKeyEntry("newalias", keyPair.getPrivate(), certPassword, new java.security.cert.Certificate[] { cert });

		FileOutputStream output = new FileOutputStream("target/keystore.jks");
		keyStore.store(output, certPassword);
		output.close();
			    
		System.out.println(javax.xml.bind.DatatypeConverter.printBase64Binary(cert.getEncoded()));
		//X509CertificateInfo.sign(cert, keyPair.getPrivate(), SIGN_ALGO_MD5WITHRSA);
	}
}