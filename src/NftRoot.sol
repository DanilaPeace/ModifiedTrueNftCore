pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

import './IndexBasis.sol';

import './interfaces/IData.sol';
import './interfaces/IIndexBasis.sol';

contract NftRoot is DataResolver, IndexResolver {
    //Errors
    uint8 constant AMOUNT_MISMATCH = 111;
    uint8 constant RARITY_AMOUNT_MISMATCH = 112;
    uint8 constant NON_EXISTENT_RARITY = 113;
    uint8 constant RARITY_OVERFLOW = 114;
    
    uint _totalMinted;
    address _addrBasis;

    // Variable to deploy the IndexBasis 
    TvmCell _codeIndexBasis;

    // To limit the tokens amount
    uint _tokenLimit;
    mapping (string => uint) _rarityTypes;
    // To count when tokens are created
    mapping (string => uint) _rarityCounter;

    constructor(
        TvmCell codeIndex, 
        TvmCell codeData, 
        TvmCell codeIndexBasis,
        uint tokenLimit,
        string[] rarityList,
        uint[] amountsForRarity
    ) public {
        require(rarityList.length == amountsForRarity.length, AMOUNT_MISMATCH, "The rarity and amounts for it doen't match");
        uint raritySumm = 0;
        for (uint256 i = 0; i < amountsForRarity.length; i++) {
            raritySumm += amountsForRarity[i];
            _rarityTypes[rarityList[i]] = amountsForRarity[i];
        }
        require(raritySumm == _tokenLimit, RARITY_AMOUNT_MISMATCH, "The number of tokens does not correspond to the total number of their types");

        tvm.accept();

        _codeIndex = codeIndex;
        _codeData = codeData;
        _codeIndexBasis = codeIndexBasis;
        _tokenLimit = tokenLimit;

        deployBasis(_codeIndexBasis);
    }

    function mintNft(string rarityType) public {
        require(_rarityTypes.exists(rarityType), NON_EXISTENT_RARITY, "Such tokens there isn't in this collection");
        require(_rarityCounter[rarityType] < _rarityTypes[rarityType], RARITY_OVERFLOW, "Tokens of this type cannot be created");

        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        new Data{stateInit: stateData, value: 1.1 ton, bounce: false}(msg.sender, _codeIndex, rarityType);

        _totalMinted++;
        _rarityCounter[rarityType]++;
    }

    function deployBasis(TvmCell codeIndexBasis) public {
        require(msg.value > 0.5 ton, 104);

        uint256 codeHasData = resolveCodeHashData();
        TvmCell state = tvm.buildStateInit({
            contr: IndexBasis,
            varInit: {
                _codeHashData: codeHasData,
                _addrRoot: address(this)
            },
            code: codeIndexBasis
        });
        
        _addrBasis = new IndexBasis{stateInit: state, value: 0.4 ton}();
    }

    function destructBasis() public view {
        IIndexBasis(_addrBasis).destruct();
    }
}