README:
-------

This is an example client library/cli tool for candlepin
(http://candlepin-project.org). It is no longer maintained. Instead, please see
the ruby client library included in candlepin/candlepin, or candlepin/python-rhsm

BUILD INFO:
----------
Install buildr(http://buildr.apache.org/) and then run
```buildr package``` to generate the candlepin-client-*.jar within target/ 


SETUP INFO:
----------
The java client requires the following information to run properly,
* Candlepin server's URL:
  This is required to connect to the remote server.
  
  For example,
      https://example.com:8443/candlepin/
  default value is,
      https://localhost:8443/candlepin/
	 
* Directory location where the client will store entitlements and keys:
  This is the directory where the client will store the entitlements
  downloaded from the server as well as your identity certificate/keys.
  
  For example,
      /home/user/.candlepin (or) C:/candlepin
  default value is,
      $HOME/.candlepin

* KeyStore location:
  This is specific to Java. Java's SSL api requires a chain of trust managers
  so that it can validate the identity of the other party as well as store
  your local identity in the form of keys, certificates. For more information,
  please visit http://java.sun.com/javase/technologies/security/. KeyStore is
  a file which is stores your keys, certificates securely. Use 'keytool'
  utility to generate your keystore. Assuming your candlepin server runs on
  tomcat, you should have a certificate stored within this keystore with the
  alias 'tomcat'. The same applies for other setups.

  For example, the keystore could be present at any readable location:
      /home/jackie/tomcat6/conf/keystore
  default value is,
      /usr/share/tomcat6/conf/keystore.

  IMPORTANT:
  ---------
  If you don't specify the right location, your client will not work. However,
  if you don't want to validate the identity of the server, you can run all
  the commands of the client with the '-k' or '--insecure' option.
    
  For example,
      ./client.sh register -u user -p pass -k
	  ./client.bat register -u user -p pass -k

  This will switch off java's check on remote server's identity and you can
  happily proceed consuming and subscribing to new products! 

PUTTING THE CONFIG TOGETHER:
---------------------------

All the above information should be specified in a proper java property file.
The client by default, looks into the location $HOME/.candlepin/candlepin.conf.
So say, you are ready to run the client, then your candlepin.conf file would
look like the following.

    #sample config only!
    serverURL=https://example.com:8443/candlepin
    candlePinHomeDirectory=/home/jackie/.candlepin
    keyStoreLocation=/home/jackie/.candlepin/keystore


If you don't want to put the config file in $HOME/.candlepin/candlepin.conf,
you can specify the location of the config file to the client using the option

    ./client.sh --configLoc=/home/jackie/documents/candlepin.conf list -a
       
A sample config file is present in the same directory as this README file.       
