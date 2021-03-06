local csr = require'openssl'.x509.req

TestCSR = {}

        function TestCSR:setUp()
                self.digest='md5'    
                self.subject = openssl.x509.name.new({
                    {C='CN'},
                    {O='kkhub.com'},
                    {CN='zhaozg'}
                })

                self.timeStamping = openssl.asn1.new_string('timeStamping','ia5')
                self.cafalse = openssl.asn1.new_string('CA:FALSE','octet')

                self.exts = {
                        {
                                object = 'extendedKeyUsage',
                                critical = true,
                                value = 'timeStamping',
                        },
                        {
                                object='basicConstraints',
                                value=self.cafalse
                        },
                        {
                                object='basicConstraints',
                                value='CA:FALSE'
                        }
                }
        
                self.attrs = {
                        {
                                object = 'extendedKeyUsage',
                                type='ia5',
                                value = 'timeStamping',
                        },
                        {
                                object='basicConstraints',
                                type='octet',
                                value=self.cafalse
                        },
                        {
                                object='basicConstraints',
                                type='octet',
                                value='CA:FALSE'
                        }
                }
                
                self.extensions = openssl.x509.extension.new_sk_extension(self.exts)
                self.attributes = openssl.x509.attribute.new_sk_attribute(self.attrs)
        end
        function TestCSR:testNew()
                local pkey = assert(openssl.pkey.new())
                local req1,req2
                req1 = assert(csr.new())
                req2 = assert(csr.new(pkey))
                t = req1:parse()
                assertIsTable(t)
                t = req2:parse()
                assertIsTable(t)
                assert(req1:verify()==false);
                assert(req2:verify());

                req1 = assert(csr.new(self.subject))
                req2 = assert(csr.new(self.subject, pkey))
                
                t = req1:parse()
                assertIsTable(t)
                t = req2:parse()
                assertIsTable(t)
                assert(req1:verify()==false);
                assert(req2:verify());
                
                req1 = assert(csr.new(self.subject,self.attributes))
                req2 = assert(csr.new(self.subject,self.attributes, pkey))
                t = req1:parse()
                assertIsTable(t)
                t = req2:parse()
                assertIsTable(t)
                

                assert(req1:verify()==false);
                assert(req2:verify());

                req1 = assert(csr.new(self.subject,self.attributes,self.extensions))
                req2 = assert(csr.new(self.subject,self.attributes,self.extensions, pkey))
                assert(req1:verify()==false);
                assert(req2:verify());
                
                t = req1:parse()
                assertIsTable(t)
                t = req2:parse()
                assertIsTable(t)

                assert(req1:verify()==false);
                assert(req2:verify());

                req1 = assert(csr.new(self.subject,self.attributes,self.extensions,pkey))
                req2 = assert(csr.new(self.subject,self.attributes,self.extensions,pkey,self.digest))
                
                t = req1:parse()
                assertIsTable(t)
                t = req2:parse()
                assertIsTable(t)
                
                assert(req1:verify());
                assert(req2:verify());

                local pem = req2:export('pem')
                assertIsString(pem)
                req2 = assert(csr.read(pem,'pem'))
                assertError(csr.read,pem,'der')
                req2 = assert(csr.read(pem,'auto'))
            
                local der = req2:export('der')
                assertIsString(der)
                req2 = assert(csr.read(der,'der'))
                assertError(csr.read,der,'pem')
                req2 = assert(csr.read(der,'auto'))
                local pubkey = req2:public()
                assertStrContains(tostring(pubkey),"openssl.evp_pkey")
                assert(req1:public(pubkey))

                assertEquals(req1:attr_count(),3+1)
                attr = req1:attribute(0)
                assertStrContains(tostring(attr),'openssl.x509_attribute')
                attr = req1:attribute(0,nil)
                assertStrContains(tostring(attr),'openssl.x509_attribute')
                assertEquals(req1:attr_count(),2+1)
                req1:attribute(attr)
                assertEquals(req1:attr_count(),3+1)
                
                assertEquals(req1:version(),0)
                assertEquals(req1:version(1),true)
                assertEquals(req1:version(),1)
                assert(req1:version(0))

                assertEquals(tostring(req1:subject()),tostring(self.subject))
                assert(req1:subject(self.subject))
                assertEquals(tostring(req1:subject()),tostring(self.subject))

                assertStrContains(tostring(req1:extensions()),'openssl.stack_of_x509_extension')
                assert(req1:extensions(self.extensions))
                assertEquals(tostring(req1:subject()),tostring(self.subject))

                local s = req1:digest()
                local r = req1:digest('sha1')
                assertEquals(r,s)
                assert(req2:check(pkey))

                local cert = req2:to_x509(pkey, 3650) -- self sign
                t = cert:parse()                
                assertStrContains(tostring(req1:to_x509(pkey, 3650)),'openssl.x509')
                assertStrContains(tostring(req2:to_x509(pkey, 3650)),'openssl.x509')

        end

function TestCSR:testIO()
local csr_data = [==[
-----BEGIN CERTIFICATE REQUEST-----
MIIBvjCCAScCAQAwfjELMAkGA1UEBhMCQ04xCzAJBgNVBAgTAkJKMRAwDgYDVQQH
EwdYSUNIRU5HMQ0wCwYDVQQKEwRUQVNTMQ4wDAYDVQQLEwVERVZFTDEVMBMGA1UE
AxMMMTkyLjE2OC45LjQ1MRowGAYJKoZIhvcNAQkBFgtzZGZAc2RmLmNvbTCBnzAN
BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA0auDcE3VFsp6J3NvyPBiiZLLnAUnUMPQ
lxmGUcbGI12UA3Z0+hNcRprDX5vD7ODUVZrR4iAozaTKUGe5w2KrhElrV/3QGzGH
jMUKvYgtlYr/vK1cAX9wx67y7YBnPbIRVqdLQRLF9Zu8T5vaMx0a/e1dzQq7EvKr
xjPVjCSgZ8cCAwEAAaAAMA0GCSqGSIb3DQEBBQUAA4GBAF3sMj2dtIcVTHAnLmHY
lemLpEEo65U7iLJUskUNMsDrNLEVt7kuWlz0uQDnuZ4qgrRVJ2BpxskTR5D5Yzzc
wSpxg0VN6+i6u9C9n4xwCe1VyteOC2In0LbxMAGL3rVFm9yDFRU3LDy3EWG6DIg/
4+QM/GW7qfmes65THZt0Hram
-----END CERTIFICATE REQUEST-----
]==]

        local x = assert(csr.read(csr_data))
        t = x:parse()
        assertIsTable(t)
        assertIsUserdata(t.subject)
        assertIsNumber(t.version)
        assertIsTable(t.req_info)
        assertIsTable(t.req_info.pubkey)
        assertIsString(t.req_info.pubkey.algorithm)
        assertIsUserdata(t.req_info.pubkey.pubkey)   
end
