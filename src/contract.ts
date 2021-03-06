import * as fs from 'fs';
import * as kleur from 'kleur';
import * as path from 'path';
import * as child from 'child_process';

import { loadFile } from './helper';
import { InMemorySigner } from '@taquito/signer';
import { MichelsonMap, TezosToolkit } from '@taquito/taquito';

export async function compileContract(): Promise<void> {
    await new Promise<void>((resolve, reject) =>
        // Compile the contract
        child.exec(
            path.join(__dirname, "../ligo/exec_ligo compile-contract " + path.join(__dirname,  "../ligo/src/d-art.minter/fa2/fa2_main.mligo") + " fa2_main"),
            (err, stdout, errout) => {
                if (err) {
                    console.log(kleur.red('Failed to compile the contract.'));
                    console.log(kleur.yellow().dim(err.toString()))
                    console.log(kleur.red().dim(errout));
                    reject();
                } else {
                    console.log(kleur.green('Contract compiled succesfully at:'))
                    // Write json contract into json file
                    console.log('  ' + path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'))
                    fs.writeFileSync(path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'), stdout)
                    resolve();
                }
            }    
        )
    );
}

export async function deployContract(): Promise<void> {
    const code = await loadFile(path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'))
    
    const  originateParam = {
        code: code,
        storage: {
            assets: {
                ledger: new MichelsonMap(),
                next_token_id: 0,
                token_metadata: new MichelsonMap(),
                operators: new MichelsonMap(),
                minters: new MichelsonMap(),
                tokens_minter: new MichelsonMap()
            },
            admin:  'tz1cihyVZ8xcFXMEWcdbLdMNABcSfZyNcCbZ',
            metadata:  MichelsonMap.fromLiteral({
                    "": "697066733a2f2f516d63657a745574704559523370754674733344464c354277674538315076715942527265717653565854673561"
                }
            )
        }
    }
    
    try {
        const toolkit = new TezosToolkit('http://florence.newby.org:8732');
        toolkit.setProvider({ signer: await InMemorySigner.fromSecretKey(process.env.PRIVATE_KEY) });

        const originationOp = await toolkit.wallet.originate(originateParam).send();
        console.log(originationOp)
        await originationOp.confirmation();
        const { address } = await originationOp.contract() 
        
        console.log(address)

    } catch (error) {
        const jsonError = JSON.stringify(error);
        console.log(kleur.red(`Fa2 multi nft token origination error ${jsonError}`));
    }
}

