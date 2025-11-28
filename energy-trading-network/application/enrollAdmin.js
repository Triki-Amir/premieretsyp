/**
 * Enroll Admin Script
 * Enrolls the admin user and adds to wallet
 * Run this first before starting the application
 */

const FabricCAServices = require('fabric-ca-client');
const { Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

async function main() {
    try {
        // Load connection profile
const ccpPath = path.resolve(__dirname,'..', '..', 'fabric-samples', 'test-network',
    'organizations', 'peerOrganizations', 'org1.example.com', 'connection-org1.json');
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create CA client
        const caInfo = ccp.certificateAuthorities['ca.org1.example.com'];
        const ca = new FabricCAServices(caInfo.url, { verify: false }, caInfo.caName);

        // Create wallet
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check if admin already enrolled
        const identity = await wallet.get('admin');
        if (identity) {
            console.log('Admin identity already exists in the wallet');
            return;
        }

        // Enroll admin
        console.log('Enrolling admin user...');
        const enrollment = await ca.enroll({ enrollmentID: 'admin', enrollmentSecret: 'adminpw' });
        
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: 'Org1MSP',
            type: 'X.509',
        };

        // Add to wallet
        await wallet.put('admin', x509Identity);
        console.log('✓ Successfully enrolled admin user and imported to wallet');

    } catch (error) {
        console.error(`Failed to enroll admin: ${error}`);
        process.exit(1);
    }
}

main();
