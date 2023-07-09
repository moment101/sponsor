Sponsor Protocol
=================

## Description

Many potential people or projects are not easy to raise funds or sponsors in the early stage. Without financial assistance, it is relatively difficult for these projects or people with potential in a certain field to develop. This contract is mainly to provide people with "guaranteed capital" to sponsor these projects, and to earn interest income by providing liquidity on the lending platform AAVe, which will be used to sponsor projects.

The sponsor can get back the principal at any time, and the sponsored person can give back to the previous or current sponsor in the future. The proportion of the reward is based on amount * timestamp. The more the sponsorship amount and the longer the time, the more reward you will get.

## Framework

<dl>
  <dt>Factory</dt>
  <dd>Deploy and create a new sponsorship project contract, anyone can put it on the shelf, you need to provide some information of the sponsored person (address, url...),
     The added projects can be queried and managed in this contract, which is convenient for front-end connection.</dd>
  <dt>LToken Proxy / LToken Implementation</dt>
  <dd>Engagement contracts for sponsors, available here Mint / Redeem,
     Responsible for investing and redeeming the funds, and transferring the proceeds to the sponsored person.</dd>
</dl>

![plot](./plot.png)

## Development

<dl>

<dt>Step 1.</dt>
<dd>Modify .env.example file, and change file name to .env</dd>

<dt>Step 2.</dt>
<dd>Deploy contracts on Anvil (locally)</dd>

```bash
anvil
make deploy-anvil
```
Check "./frontend/constants.js" file, factoryAddress is the factory's address on Anvil
Open "./frontand/index.html with Live Server, interact with browser install Metamask
Add anvil local testnet to Metamask

<dt>Step 3.</dt>
<dd>Deploy contracts on Sepolia testnet</dd>

```bash
make deploy-sepolia
```
</dl>

## Testing

```bash
forge test -vvv
```


## Usage
