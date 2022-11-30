// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "hardhat/console.sol";

contract PokemonNFT {
    uint8 public constant MAX_BIRTH = 4;
    uint256 private constant _BITMASK_ID = (1 << 64) - 1;
    uint256 private constant _BITMASK_HP = (1 << 16) - 1;
    uint256 private constant _BITMASK_GENE = (1 << 8) - 1;

    uint256 private constant _BITMASK_HP_POSITION = 64;
    uint256 private constant _BITMASK_HP_CHILD_COUNT_POSITION = 80;
    uint256 private constant _BITMASK_DOMINANT_GENE_POSITION = 128;
    uint256 private constant _BITMASK_R1_GENE_POSITION = 176;
    uint256 private constant _BITMASK_R2_GENE_POSITION = 224;

    uint64 public pokemonCounter = 1;

    // total 256 bit
    struct Pokemon {
        uint64 id;
        uint16 hp;
        // 4 uint8 = 32 bit
        uint8 childCount;
        uint8 feather;
        uint8 body;
        // bird,plant,bug,beast,reptile,aqua
        // it determined by most part of the class
        // if have 3 aqua part then its aqua
        uint8 pokemonType;
        //18 uint8 = 144 bit
        Gene dominant;
        Gene r1;
        Gene r2;
    }

    struct Gene {
        uint8 eyes;
        uint8 ears;
        uint8 back;
        uint8 horn;
        uint8 mouth;
        uint8 tail;
    }

    struct Parent {
        uint64 parentId;
        uint64 parentId2;
    }

    // pokemon => Parents
    mapping(uint64 => uint256[2]) public parents;

    // pokemon => children(4 children in uint256)
    mapping(uint256 => uint256[4]) public childrens;

    // wallet => pokemons
    mapping(address => uint256[]) public userPokemons;

    constructor() {
        userPokemons[msg.sender].push(0x000102030405060708090a0b0c0d0e0f100807060501ffff0000000000000001);
        userPokemons[msg.sender].push(0x00000000000000000000000000000000000000000000ffff0000000000000001);
    }

    function getId(uint256 pokemon) public view returns (uint256) {
        console.log(pokemon & _BITMASK_ID); // 0-63 first64Bit, print(6)
        console.logBytes(abi.encodePacked(pokemon & _BITMASK_ID)); // 0-63 first64Bit, print(6)
        return pokemon & _BITMASK_ID;
    }

    function getHp(uint256 pokemon) public pure returns (uint16) {
        return uint16((pokemon >> _BITMASK_HP_POSITION) & _BITMASK_HP);
    }

    function getProperty(uint256 pokemon)
        public
        pure
        returns (
            uint8 childCount,
            uint8 feather,
            uint8 body,
            uint8 pokemonType
        )
    {
        childCount = uint8((pokemon >> _BITMASK_HP_CHILD_COUNT_POSITION) & _BITMASK_GENE);
        feather = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 8)) & _BITMASK_GENE);
        body = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 16)) & _BITMASK_GENE);
        pokemonType = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 24)) & _BITMASK_GENE);
    }

    function getDominantGenes(uint256 pokemon) public pure returns (Gene memory gene) {
        gene.eyes = uint8((pokemon >> _BITMASK_DOMINANT_GENE_POSITION) & _BITMASK_GENE);
        gene.ears = uint8((pokemon >> (_BITMASK_DOMINANT_GENE_POSITION + 8)) & _BITMASK_GENE);
        gene.back = uint8((pokemon >> (_BITMASK_DOMINANT_GENE_POSITION + 16)) & _BITMASK_GENE);
        gene.horn = uint8((pokemon >> (_BITMASK_DOMINANT_GENE_POSITION + 24)) & _BITMASK_GENE);
        gene.mouth = uint8((pokemon >> (_BITMASK_DOMINANT_GENE_POSITION + 32)) & _BITMASK_GENE);
        gene.tail = uint8((pokemon >> (_BITMASK_DOMINANT_GENE_POSITION + 40)) & _BITMASK_GENE);
    }

    function getR1Genes(uint256 pokemon) public pure returns (Gene memory gene) {
        gene.eyes = uint8((pokemon >> _BITMASK_R1_GENE_POSITION) & _BITMASK_GENE);
        gene.ears = uint8((pokemon >> (_BITMASK_R1_GENE_POSITION + 8)) & _BITMASK_GENE);
        gene.back = uint8((pokemon >> (_BITMASK_R1_GENE_POSITION + 16)) & _BITMASK_GENE);
        gene.horn = uint8((pokemon >> (_BITMASK_R1_GENE_POSITION + 24)) & _BITMASK_GENE);
        gene.mouth = uint8((pokemon >> (_BITMASK_R1_GENE_POSITION + 32)) & _BITMASK_GENE);
        gene.tail = uint8((pokemon >> (_BITMASK_R1_GENE_POSITION + 40)) & _BITMASK_GENE);
    }

    function getR2Genes(uint256 pokemon) public pure returns (Gene memory gene) {
        gene.eyes = uint8((pokemon >> _BITMASK_R2_GENE_POSITION) & _BITMASK_GENE);
        gene.ears = uint8((pokemon >> (_BITMASK_R2_GENE_POSITION + 8)) & _BITMASK_GENE);
        gene.back = uint8((pokemon >> (_BITMASK_R2_GENE_POSITION + 16)) & _BITMASK_GENE);
        gene.horn = uint8((pokemon >> (_BITMASK_R2_GENE_POSITION + 24)) & _BITMASK_GENE);
        gene.mouth = uint8((pokemon >> (_BITMASK_R2_GENE_POSITION + 32)) & _BITMASK_GENE);
        gene.tail = uint8((pokemon >> (_BITMASK_R2_GENE_POSITION + 40)) & _BITMASK_GENE);
    }

    function createGene(
        uint8 eyes,
        uint8 ears,
        uint8 back,
        uint8 horn,
        uint8 mouth,
        uint8 tail
    ) public view returns (uint48 gene) {
        gene =
            gene |
            uint48(eyes) |
            (uint48(ears) << 8) |
            (uint48(back) << 16) |
            (uint48(horn) << 24) |
            (uint48(mouth) << 32) |
            (uint48(tail) << 40);
        console.logBytes(abi.encodePacked(gene));
    }

    function createProperty() public view returns (uint32 property) {
        // solhint-disable not-rely-on-time
        uint32 feather = uint32((block.timestamp * pokemonCounter) % 32);
        uint32 body = uint32((block.timestamp * block.difficulty * pokemonCounter) % 16);
        uint32 pokemonType = uint32((block.timestamp * tx.gasprice * pokemonCounter) % 6);
        // solhint-enable not-rely-on-time

        property = property | (feather << 8) | (body << 16) | (pokemonType << 24);
        console.logBytes(abi.encodePacked(property));
    }

    function createPokemon(
        uint48 d,
        uint48 r1,
        uint48 r2
    ) public returns (uint256 pokemon) {
        uint256 id = uint256(pokemonCounter++);
        uint256 hp = uint256(0xffff);
        uint256 property = uint256(createProperty());
        pokemon =
            pokemon |
            id |
            (hp << _BITMASK_HP_POSITION) |
            (property << _BITMASK_HP_CHILD_COUNT_POSITION) |
            (uint256(d) << _BITMASK_DOMINANT_GENE_POSITION) |
            (uint256(r1) << _BITMASK_R1_GENE_POSITION) |
            (uint256(r2) << _BITMASK_R2_GENE_POSITION);
        console.logBytes(abi.encodePacked(pokemon));
    }

    function getPokemon(uint256 pokemon) public pure returns (bytes memory) {
        return abi.encodePacked(pokemon);
    }
}
