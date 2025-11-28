const fs = require('fs');
const path = require('path');

const basePath = path.resolve(__dirname, '..', '..', 'fabric-samples', 'test-network', 'organizations');

// Read certificates
const peerTlsCert = fs.readFileSync(
    path.join(basePath, 'peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt'),
    'utf8'
);

const caTlsCertPath = path.join(basePath, 'peerOrganizations/org1.example.com/msp/cacerts/localhost-7054-ca-org1.pem');
let caTlsCert = '';
if (fs.existsSync(caTlsCertPath)) {
    caTlsCert = fs.readFileSync(caTlsCertPath, 'utf8');
}

const connectionProfile = {
    name: "test-network-org1",
    version: "1.0.0",
    client: {
        organization: "Org1",
        connection: {
            timeout: {
                peer: {
                    endorser: "300"
                }
            }
        }
    },
    organizations: {
        Org1: {
            mspid: "Org1MSP",
            peers: ["peer0.org1.example.com"],
            certificateAuthorities: ["ca.org1.example.com"]
        }
    },
    peers: {
        "peer0.org1.example.com": {
            url: "grpcs://localhost:7051",
            tlsCACerts: {
                pem: peerTlsCert
            },
            grpcOptions: {
                "ssl-target-name-override": "peer0.org1.example.com",
                "hostnameOverride": "peer0.org1.example.com"
            }
        }
    },
    certificateAuthorities: {
        "ca.org1.example.com": {
            url: "https://localhost:7054",
            caName: "ca-org1",
            tlsCACerts: {
                pem: [caTlsCert]
            },
            httpOptions: {
                verify: false
            }
        }
    }
};

const outputPath = path.join(basePath, 'peerOrganizations/org1.example.com/connection-org1.json');
fs.writeFileSync(outputPath, JSON.stringify(connectionProfile, null, 2));
console.log('✓ Connection profile created successfully at:', outputPath);
console.log('✓ Peer TLS certificate loaded');
console.log('✓ CA certificate loaded');
