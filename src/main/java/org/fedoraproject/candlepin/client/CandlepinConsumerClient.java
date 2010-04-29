/**
 * Copyright (c) 2009 Red Hat, Inc.
 *
 * This software is licensed to you under the GNU General Public License,
 * version 2 (GPLv2). There is NO WARRANTY for this software, express or
 * implied, including the implied warranties of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
 * along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 *
 * Red Hat trademarks are not licensed under GPLv2. No permission is
 * granted to use or replicate Red Hat trademarks that are incorporated
 * in this software or its documentation.
 */
package org.fedoraproject.candlepin.client;

import java.io.File;
import java.io.FileWriter;
import java.math.BigInteger;
import java.net.URL;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import javax.ws.rs.core.Response;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.UsernamePasswordCredentials;
import org.apache.commons.httpclient.auth.AuthScope;
import org.apache.commons.httpclient.protocol.Protocol;
import org.fedoraproject.candlepin.client.model.Consumer;
import org.fedoraproject.candlepin.client.model.Entitlement;
import org.fedoraproject.candlepin.client.model.EntitlementCertificate;
import org.fedoraproject.candlepin.client.model.Pool;
import org.jboss.resteasy.client.ClientResponse;
import org.jboss.resteasy.client.ProxyFactory;
import org.jboss.resteasy.client.core.executors.ApacheHttpClientExecutor;
import org.jboss.resteasy.plugins.providers.RegisterBuiltin;
import org.jboss.resteasy.spi.ResteasyProviderFactory;

/**
 * CandlepinConsumerClient
 */
public class CandlepinConsumerClient {

    private String url;
    private String dir = "/home/bkearney/.candlepin";
    private String consumerDirName = dir + File.separator + "consumer";
    private String entitlementDirName = dir + File.separator + "entitlements";
    private String certFileName = consumerDirName + File.separator + "cert.pem";
    private String keyFileName = consumerDirName + File.separator + "key.pem";

    public CandlepinConsumerClient(String url) {
        this.url = url;
        RegisterBuiltin.register(ResteasyProviderFactory.getInstance());
    }

    /**
     * Returns true if the client is already registered
     * 
     * @return true if registered
     */
    public boolean isRegistered() {
        return getUUID() != null;
    }

    /**
     * Returns the UUID for the consumer, or null if not registered.
     * 
     * @return the UUID of the consumer
     */
    public String getUUID() {
        String uuid = null;
        File certFile = new File(certFileName);
        if (certFile.exists()) {
            uuid = PemUtility.extractUUID(certFileName);
        }
        return uuid;
    }

    /**
     * Registers a consumer with a provided name and type. The credentials are
     * user for authentication.
     * 
     * @return The UUID of the new consumer.
     */
    public String register(String username, String password, String name,
        String type) {
        ICandlepinConsumerClient client = this.clientWithCredentials(username,
            password);
        Consumer cons = new Consumer();
        cons.setName(name);
        cons.setType(type);
        cons = client.register(cons);
        recordIdentity(cons);
        return cons.getUuid();
    }

    /**
     * Register to an existing consumer. The credentials are user for
     * authentication.
     * 
     * @return true if the registration succeeded
     */
    public boolean registerExisting(String username, String password,
        String uuid) {
        ICandlepinConsumerClient client = this.clientWithCredentials(username,
            password);
        if (isRegistered()) {
            ClientResponse<Consumer> response = client.getConsumer(uuid);
            if (response.getResponseStatus().equals(Response.Status.OK)) {
                recordIdentity(response.getEntity());
                return true;
            }
            else {
                return false;
            }
        }
        return false;
    }

    /**
     * Remove he consumer from candlepin and all of the entitlements which the
     * conumser have subscribed to.
     * 
     * @return True if the consumr is no longer registered.
     */
    public boolean unRegister() {
        ICandlepinConsumerClient client = clientWithCert();
        boolean success = false;
        if (isRegistered()) {
            ClientResponse<Object> response = client.deleteConsumer(getUUID());
            System.out.println(response.getResponseStatus());
            success = (response.getResponseStatus()
                .equals(Response.Status.NO_CONTENT));
            if (success) {
                removeFiles();
            }
        }
        return success;
    }

    /**
     * List the pools which the consumer could subscribe to
     * 
     * @return the list of exception
     */
    public List<Pool> listPools() {
        ICandlepinConsumerClient client = clientWithCert();
        List<Pool> pools = client.listPools(getUUID());
        return pools;
    }

    public List<Entitlement> bindByPool(Long poolId) {
        ICandlepinConsumerClient client = clientWithCert();
        return client.bindByEntitlementID(getUUID(), poolId).getEntity();
    }
    

    public boolean updateEntitlementCertificates() {
        mkdir(entitlementDirName);
        ICandlepinConsumerClient client = clientWithCert();
        List<EntitlementCertificate> certs = client
            .getEntitlementCertificates(getUUID());
        Set<BigInteger> certSerials = new java.util.HashSet<BigInteger>();
        //EntitlementCertificate
        for (EntitlementCertificate cert : certs) {
            String entCertFileName = entitlementDirName + File.separator +
                cert.getSerial() + "-cert.pem";
            String entKeyFileName = entitlementDirName + File.separator +
                cert.getSerial() + "-key.pem";
            dumpToFile(entCertFileName, cert.getCert());
            dumpToFile(entKeyFileName, cert.getKey());
        }
        return true;
    }
    
    public List<EntitlementCertificate> getCurrentEntitlementCertificates() {
        try {
            mkdir(entitlementDirName);
            List<EntitlementCertificate> certs = new ArrayList<EntitlementCertificate>();
            File entitlementDir = new File(entitlementDirName);      
            for (String filename : entitlementDir.list()) {
                if (filename.endsWith("-cert.pem")) {
                    X509Certificate cert = PemUtility.readCert(filename);
                    EntitlementCertificate entCert = new EntitlementCertificate();
                    //entCert.setCertAsString(cert.getEncoded());
                    entCert.setSerial(cert.getSerialNumber().longValue());
                    //TODO ADD THE KEY
                    certs.add(entCert);
                }
            }
    
            return certs;
        }
        catch (Exception e) {
            throw new ClientException(e);
        }            
    }

    protected ICandlepinConsumerClient clientWithCert() {
        try {
            Protocol customHttps = new Protocol("https",
                new CustomSSLProtocolSocketFactory(certFileName, keyFileName),
                443);
            Protocol.registerProtocol("https", customHttps);
            HttpClient httpclient = new HttpClient();
            URL hostUrl = new URL(url);
            httpclient.getHostConfiguration().setHost(hostUrl.getHost(),
                hostUrl.getPort(), customHttps);
            ICandlepinConsumerClient client = ProxyFactory.create(
                ICandlepinConsumerClient.class, url,
                new ApacheHttpClientExecutor(httpclient));
            return client;
        }
        catch (Exception e) {
            throw new ClientException(e);
        }

    }

    protected ICandlepinConsumerClient clientWithCredentials(String username,
        String password) {
        HttpClient httpclient = new HttpClient();
        httpclient.getParams().setAuthenticationPreemptive(true);
        UsernamePasswordCredentials creds = new UsernamePasswordCredentials(
            username, password);
        httpclient.getState().setCredentials(AuthScope.ANY, creds);

        ICandlepinConsumerClient client = ProxyFactory.create(
            ICandlepinConsumerClient.class, url, new ApacheHttpClientExecutor(
                httpclient));
        return client;
    }

    protected void recordIdentity(Consumer aConsumer) {        
        mkdir(consumerDirName);
        System.out.println(aConsumer.getIdCert().getCert());
        dumpToFile(certFileName, aConsumer.getIdCert().getCert());
        dumpToFile(keyFileName, aConsumer.getIdCert().getKey());
    }

    protected void mkdir(String dirName) {
        try {
            File dir = new File(dirName);
            if (!dir.exists()) {
                dir.mkdirs();
            }
        }
        catch (Exception e) {
            throw new ClientException(e);
        }
    }

    protected void removeFiles() {
        String[] files = { certFileName, keyFileName };
        for (String fileName : files) {
            File file = new File(fileName);
            file.delete();
        }
    }

    protected void dumpToFile(String filename, String contents) {
        try {
            File file = new File(filename);
            FileWriter fout = new FileWriter(file);

            fout.append(contents);
            fout.close();
        }
        catch (Exception e) {
            throw new ClientException(e);
        }
    }

}
