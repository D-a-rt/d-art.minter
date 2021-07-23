# d-art.minter

## Introduction:

Minter contract in order to mint token on the Tezos blockchain, wrapped into a tiny CLI to compile and deploy the contract.

## Install the CLI (TypeScript):

To install all the dependencies of the project please run:
    
    $ cd /d-art.minter 
    $ npm install
    $ npm run-script build
    $ npm install -g
    
In order to run the tests:

    $ npm run-script test
        
The different available commands are:

    $ d-art.contracts compile-contract
        (Compile the contract contained in the project)

    $ d-art.contracts deploy-contract
        (Deploy the contract previously compiled in the project)


# FA2 NFT Token

## Storage definition

This section is responsible to list and explain the storage of the contract.

``` ocaml
type nft_asset_storage = {
  assets : assets;
  admin : admin_storage;
  metadata: (string, bytes) big_map; (* contract metadata *)
}
```

### assets

The first field is `assets` and has it's own definition:

``` ocaml

type nft_asset_storage = {
  assets : assets;
  ...
}

type assets = {
  ledger : ledger;
  token_metadata : nft_meta;
  next_token_id : token_id;
  operators : operator_storage;
  minters : minters;
  tokens_minter : tokens_minter;
}

type ledger = (token_id, address) big_map

type nft_meta = (nat, token_metadata) big_map

type token_metadata =
[@layout:comb]
{
    token_id: token_id;
    token_info: ((string, bytes) map);
}

type token_id = nat

type operator_storage = ((address * (address * token_id)), unit) big_map

type minters = (address, unit) big_map

type tokens_minter = (token_id, address) big_map

```

The assets storage is responsible to hold all the information of the minted tokens, which token belongs to who (`ledger`), what are the tokens metadata (`token_metadata`), the next `token_id`, the list of contracts that can perform operation on behalf of a user `operators`, the list of minting authorized address  `minters`, and `tokens_minter` the big_map which address created which token in order to ease the royalties system.

### admin

The second field is `admin` and has it's own definition:

``` ocaml

type nft_asset_storage = {
    ...
    admin : admin_storage;
    ...
}

type admin_storage = {
  admin : address;
}

```

The admin storage only hold the address of the admin and is here in order to add or remove authorized minter 

### metadata

The thirs field is `metadata`:


``` ocaml

type nft_asset_storage = {
    ...
    metadata: (string, bytes) big_map; (* contract metadata *)
}
```

It holds the contract metadata, general information of the contract like name, description...


## Entrypoints

The different entrypoints of the contract are define by:

``` ocaml
type nft_asset_entrypoints =
    | Assets of fa2_entry_points
    | Mint of mint_token_param
    | Admin of admin_minter_entrypoints
```

### Assets

The `Assets` entrypoint is responsible to transfer token, update the authorized operators, and transfering a token while sending a royaltie to the minter.

``` ocaml
type fa2_entry_points =
  | Minter_royalties of royalties_param
  | Transfer of transfer list
  | Balance_of of balance_of_param
  | Update_operators of update_operator list

(* Minter_royalties param *)
type royalties_param =
[@layout:comb] 
{
  token_id: token_id;
  fee: tez;
}

(* Transfer param *)
type transfer =
[@layout:comb]
{
  from_ : address;
  destinations : transfer_destination list;
}

(* Balance_of param *)
type balance_of_param =
[@layout:comb]
{
  requests : balance_of_request list;
  callback : (balance_of_response list) contract;
}


```

`Minter_royalties` : Retrieve the minter from the token_id in the `tokens_minter` big_map and transfer the fee specified

`Transfer` : Transfer tokens

`Balance_of` : get the balance for a token_id and an owner

`Update_operators` : Add or remove operator for token

### Mint

The `Mint` entrypoint is responsible to mint tokens.

``` ocaml
type mint_token_param =
[@layout:comb]
{
    token_metadata: token_input_metadata;
    owner : address;
}

type token_input_metadata = 
[@layout:comb]
{
    token_id: token_id;
    token_info: ((string, bytes) map);
}

```

Give it an owner and token_metadata and the token will be created. The entrypoint is only accessible for the authorized minter, in the `minters big_map`

### Admin

The admin is responsible to add or remove minters for the `minters big_map`

``` ocaml
type admin_minter_entrypoints =
    | Add_minter of address
    | Remove_minter of address
```

`Add_minter`: Add a minter to the big_map

`Rmove_minter`: Remove a minter to the big_map
