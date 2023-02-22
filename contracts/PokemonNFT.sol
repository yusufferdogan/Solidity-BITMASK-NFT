// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IPokemon.sol";

contract PokemonNFT is ERC721, ERC721Enumerable, IPokemon {
    uint8 public constant MAX_BIRTH = 4;
    uint256 private constant _BITMASK_ID = (1 << 64) - 1;
    uint256 private constant _BITMASK_HP = (1 << 16) - 1;
    uint256 private constant _BITMASK_GENE = (1 << 8) - 1;

    uint256 private constant _BITMASK_HP_POSITION = 64;
    uint256 private constant _BITMASK_HP_CHILD_COUNT_POSITION = 80;
    uint256 private constant _BITMASK_DOMINANT_GENE_POSITION = 128;
    uint256 private constant _BITMASK_R1_GENE_POSITION = 176;
    uint256 private constant _BITMASK_R2_GENE_POSITION = 224;

    uint64 public pokemonCounter = 0;
    IERC20 public immutable pokToken;

    // total 256 bit
    struct Pokemon {
        uint64 id;
        uint16 hp;
        Property property;
        Gene dominant;
        Gene r1;
        Gene r2;
    }

    // total 48 bit
    struct Gene {
        uint8 eyes;
        uint8 ears;
        uint8 back;
        uint8 horn;
        uint8 mouth;
        uint8 tail;
    }

    //total 32 bit
    struct Property {
        uint8 childCount;
        uint8 feather;
        uint8 body;
        // bird,plant,bug,beast,reptile,aqua
        uint8 pokemonType;
    }

    // pokemon ID => parents ID
    mapping(uint256 => uint256[2]) public parents;

    // pokemon ID => children ID
    mapping(uint256 => uint256[4]) public childrens;

    // pokemon ID => Pokemon Owner
    mapping(uint256 => address) public pokemonOwner;

    //pokemon ID => pokemon
    mapping(uint256 => uint256) public pokemons;

    constructor(address pokTokenAddress) ERC721("Foo721", "F721") {
        pokToken = IERC20(pokTokenAddress);
    }

    function breedPokemon(uint64 pokemonID1, uint64 pokemonID2) public {
        uint256 pokemon1 = pokemons[pokemonID1];
        uint256 pokemon2 = pokemons[pokemonID2];
        uint8 childCount1 = getChildCount(pokemon1);
        uint8 childCount2 = getChildCount(pokemon2);
        uint256 totalCost = computeBreedCost(childCount1) + computeBreedCost(childCount2);

        if (pokemonOwner[pokemonID1] != msg.sender || pokemonOwner[pokemonID2] != msg.sender) revert InvalidPokemons();
        if (childCount1 >= MAX_BIRTH || childCount2 >= MAX_BIRTH) revert MaxBirthReached();

        uint256 id = uint256(++pokemonCounter);
        (uint48 d, uint48 r1, uint48 r2) = computeGenes(pokemon1, pokemon2);
        uint256 pokemon = createPokemon(id, d, r1, r2);

        //set pokemon
        pokemons[id] = pokemon;
        //set owner of pokemon
        pokemonOwner[id] = msg.sender;

        //set parents of new breed pokemon
        parents[id][0] = pokemonID1;
        parents[id][1] = pokemonID2;

        childrens[pokemonID1][childCount1] = id;
        require(pokToken.transferFrom(msg.sender, address(this), totalCost), "Tx Error");
    }

    function computeBreedCost(uint8 childCount) private pure returns (uint256) {
        if (childCount == 1) return 500;
        else if (childCount == 2) return 1500;
        else if (childCount == 3) return 3500;
        else return 7500;
    }

    function computeGenes(uint256 pokemon1, uint256 pokemon2)
        private
        returns (
            uint48 d,
            uint48 r1,
            uint48 r2
        )
    {}

    function createPokemon(
        uint256 id,
        uint48 d,
        uint48 r1,
        uint48 r2
    ) public view returns (uint256 pokemon) {
        //uint256 id = uint256(++pokemonCounter);
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
    }

    function getId(uint256 pokemon) public pure returns (uint256) {
        return pokemon & _BITMASK_ID;
    }

    function getHp(uint256 pokemon) public pure returns (uint16) {
        return uint16((pokemon >> _BITMASK_HP_POSITION) & _BITMASK_HP);
    }

    function getChildCount(uint256 pokemon) public pure returns (uint8) {
        return uint8((pokemon >> _BITMASK_HP_CHILD_COUNT_POSITION) & _BITMASK_GENE);
    }

    function getProperty(uint256 pokemon) public pure returns (Property memory property) {
        property.childCount = uint8((pokemon >> _BITMASK_HP_CHILD_COUNT_POSITION) & _BITMASK_GENE);
        property.feather = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 8)) & _BITMASK_GENE);
        property.body = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 16)) & _BITMASK_GENE);
        property.pokemonType = uint8((pokemon >> (_BITMASK_HP_CHILD_COUNT_POSITION + 24)) & _BITMASK_GENE);
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
    ) public pure returns (uint48 gene) {
        gene =
            gene |
            uint48(eyes) |
            (uint48(ears) << 8) |
            (uint48(back) << 16) |
            (uint48(horn) << 24) |
            (uint48(mouth) << 32) |
            (uint48(tail) << 40);
    }

    function createProperty() public view returns (uint32 property) {
        // solhint-disable not-rely-on-time
        uint32 feather = uint32((block.timestamp * pokemonCounter) % 32);
        uint32 body = uint32((block.timestamp * block.difficulty * pokemonCounter) % 16);
        uint32 pokemonType = uint32((block.timestamp * tx.gasprice * pokemonCounter) % 6);
        // solhint-enable not-rely-on-time
        property = property | (feather << 8) | (body << 16) | (pokemonType << 24);
    }

    function getPokemon(uint256 pokemon) public pure returns (bytes memory) {
        return abi.encodePacked(pokemon);
    }

    function incrementChildCount(uint256 pokemon) public pure returns (uint256) {
        return pokemon + 2**80;
    }

    function decrementHp(uint256 pokemon, uint16 amount) public pure returns (uint256) {
        return pokemon - 2**64 * amount;
    }

    function getOnChainNFT(uint256 pokemon) public pure returns (string memory) {
        string memory enclosing = "</text>";
        Property memory property = getProperty(pokemon);
        Gene memory d = getDominantGenes(pokemon);
        Gene memory r1 = getR1Genes(pokemon);
        Gene memory r2 = getR2Genes(pokemon);

        string memory nft = string.concat(
            "<svg width='500' height='500' style='background-color:white'>",
            string.concat("<text x='10' y='50'>ID:", string.concat(Strings.toString(getId(pokemon)), enclosing)),
            string.concat("<text x='10' y='80'>HP:", string.concat(Strings.toString(getHp(pokemon)), enclosing)),
            string.concat(
                "<text x='10' y='110'>NumberOfChild:",
                string.concat(Strings.toString(property.childCount), enclosing)
            ),
            string.concat(
                "<text x='10' y='140'>Feather:",
                string.concat(Strings.toString(property.feather), enclosing)
            ),
            string.concat("<text x='10' y='170'>Body:", string.concat(Strings.toString(property.body), enclosing))
        );

        string memory nft2 = string.concat(
            "<text x='10' y='300'>D GENES</text>",
            string.concat("<text x='10' y='330'>Eyes:", string.concat(Strings.toString(d.eyes), enclosing)),
            string.concat("<text x='10' y='360'>Ears:", string.concat(Strings.toString(d.ears), enclosing)),
            string.concat("<text x='10' y='390'>Back:", string.concat(Strings.toString(d.back), enclosing)),
            string.concat("<text x='10' y='420'>Horn:", string.concat(Strings.toString(d.horn), enclosing)),
            string.concat("<text x='10' y='450'>Mouth:", string.concat(Strings.toString(d.mouth), enclosing)),
            string.concat("<text x='10' y='480'>Tail:", string.concat(Strings.toString(d.tail), enclosing))
        );

        string memory nft3 = string.concat(
            "<text x='180' y='300'>R1 GENES</text>",
            string.concat("<text x='180' y='330'>Eyes:", string.concat(Strings.toString(r1.eyes), enclosing)),
            string.concat("<text x='180' y='360'>Ears:", string.concat(Strings.toString(r1.ears), enclosing)),
            string.concat("<text x='180' y='390'>Back:", string.concat(Strings.toString(r1.back), enclosing)),
            string.concat("<text x='180' y='420'>Horn:", string.concat(Strings.toString(r1.horn), enclosing)),
            string.concat("<text x='180' y='450'>Mouth:", string.concat(Strings.toString(r1.mouth), enclosing)),
            string.concat("<text x='180' y='480'>Tail:", string.concat(Strings.toString(r1.tail), enclosing))
        );

        string memory nft4 = string.concat(
            "<text x='350' y='300'>R2 GENES</text>",
            string.concat("<text x='350' y='330'>Eyes:", string.concat(Strings.toString(r2.eyes), enclosing)),
            string.concat("<text x='350' y='360'>Ears:", string.concat(Strings.toString(r2.ears), enclosing)),
            string.concat("<text x='350' y='390'>Back:", string.concat(Strings.toString(r2.back), enclosing)),
            string.concat("<text x='350' y='420'>Horn:", string.concat(Strings.toString(r2.horn), enclosing)),
            string.concat("<text x='350' y='450'>Mouth:", string.concat(Strings.toString(r2.mouth), enclosing)),
            string.concat("<text x='350' y='480'>Tail:", string.concat(Strings.toString(r2.tail), enclosing))
        );

        return string.concat(nft, nft2, nft3, nft4, "</svg>");
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}
