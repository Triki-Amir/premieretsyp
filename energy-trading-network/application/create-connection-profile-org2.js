const fs = require('fs');
const path = require('path');

const basePath = path.resolve(__dirname, '..', '..', 'fabric-samples', 'test-network', 'organizations');

const peerTlsCertPath = path.join(basePath, 'peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt');
const caTlsCertPath = path.join(basePath, 'peerOrganizations/org2.example.com/msp/cacerts/localhost-8054-ca-org2.pem');

if (!fs.existsSync(peerTlsCertPath)) {
  console.error('Peer TLS cert not found for Org2 at', peerTlsCertPath);
  process.exit(2);
}

const peerTlsCert = fs.readFileSync(peerTlsCertPath, 'utf8');
let caTlsCert = '';
if (fs.existsSync(caTlsCertPath)) {
  caTlsCert = fs.readFileSync(caTlsCertPath, 'utf8');
}

const connectionProfile = {
  name: 'test-network-org2',
  version: '1.0.0',
  client: { organization: 'Org2' },
  organizations: {
    Org2: {
      mspid: 'Org2MSP',
      peers: ['peer0.org2.example.com'],
      certificateAuthorities: ['ca.org2.example.com']
    }
  },
  peers: {
    'peer0.org2.example.com': {
      url: 'grpcs://localhost:9051',
      tlsCACerts: { pem: peerTlsCert },
      grpcOptions: {
        'ssl-target-name-override': 'peer0.org2.example.com',
        'hostnameOverride': 'peer0.org2.example.com'
      }
    }
  },
  certificateAuthorities: {
    'ca.org2.example.com': {
      url: 'https://localhost:8054',
      caName: 'ca-org2',
      tlsCACerts: { pem: [caTlsCert] },
      httpOptions: { verify: false }
    }
  }
};

const outputPath = path.join(basePath, 'peerOrganizations/org2.example.com/connection-org2.json');
fs.writeFileSync(outputPath, JSON.stringify(connectionProfile, null, 2));
console.log('✓ Connection profile created for Org2 at:', outputPath);
