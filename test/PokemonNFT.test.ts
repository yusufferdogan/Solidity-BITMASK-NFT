import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
//eslint-disable-next-line
import { expect, assert } from 'chai';
//eslint-disable-next-line
import { Contract, ContractFactory, constants } from 'ethers';
import { ethers } from 'hardhat';

const name: string = 'PokemonNFT';

describe(name, () => {
  //eslint-disable-next-line
  let contract: Contract;
  //eslint-disable-next-line
  let owner: SignerWithAddress;
  //eslint-disable-next-line
  let addresses: SignerWithAddress[];
  let factory: ContractFactory;

  // hooks
  before(async () => {
    [owner, ...addresses] = await ethers.getSigners();
    factory = await ethers.getContractFactory(name);
  });

  beforeEach(async () => {
    contract = await factory.deploy();
  });

  // mint tests
  it('should MINT successfully', async () => {});
});
