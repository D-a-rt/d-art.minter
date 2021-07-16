"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deployContract = exports.compileContract = void 0;
const fs = __importStar(require("fs"));
const kleur = __importStar(require("kleur"));
const path = __importStar(require("path"));
const child = __importStar(require("child_process"));
const helper_1 = require("./helper");
const signer_1 = require("@taquito/signer");
const taquito_1 = require("@taquito/taquito");
function compileContract() {
    return __awaiter(this, void 0, void 0, function* () {
        yield new Promise((resolve, reject) => 
        // Compile the contract
        child.exec(path.join(__dirname, "../ligo/exec_ligo compile-contract " + path.join(__dirname, "../ligo/src/d-art.minter/fa2/fa2_main.mligo") + " fa2_main"), (err, stdout, errout) => {
            if (err) {
                console.log(kleur.red('Failed to compile the contract.'));
                console.log(kleur.yellow().dim(err.toString()));
                console.log(kleur.red().dim(errout));
                reject();
            }
            else {
                console.log(kleur.green('Contract compiled succesfully at:'));
                // Write json contract into json file
                console.log('  ' + path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'));
                fs.writeFileSync(path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'), stdout);
                resolve();
            }
        }));
    });
}
exports.compileContract = compileContract;
function deployContract() {
    return __awaiter(this, void 0, void 0, function* () {
        const code = yield helper_1.loadFile(path.join(__dirname, '../ligo/src/d-art.minter/fa2/fa2_main.tz'));
        const originateParam = {
            code: code,
            storage: {
                assets: {
                    ledger: new taquito_1.MichelsonMap(),
                    next_token_id: 0,
                    token_metadata: new taquito_1.MichelsonMap(),
                    operators: new taquito_1.MichelsonMap(),
                    minters: new taquito_1.MichelsonMap(),
                    tokens_minter: new taquito_1.MichelsonMap()
                },
                admin: 'tz1cihyVZ8xcFXMEWcdbLdMNABcSfZyNcCbZ',
                metadata: new taquito_1.MichelsonMap()
            }
        };
        try {
            const toolkit = new taquito_1.TezosToolkit('https://edonet.smartpy.io');
            toolkit.setProvider({ signer: yield signer_1.InMemorySigner.fromSecretKey('edskS9Gdwb6GqG3arwBHi2K5n5D8do8ygqsBvy5nTpDfJ37iLJSbAML8UymBUJGbFUzdqQ3USWFuyphSPzAmxWRqNG9q9fhfzr') });
            const originationOp = yield toolkit.wallet.originate(originateParam).send();
            console.log(originationOp);
            yield originationOp.confirmation();
            const { address } = yield originationOp.contract();
            console.log(address);
        }
        catch (error) {
            const jsonError = JSON.stringify(error);
            console.log(kleur.red(`Fa2 multi nft token origination error ${jsonError}`));
        }
    });
}
exports.deployContract = deployContract;
//# sourceMappingURL=contract.js.map