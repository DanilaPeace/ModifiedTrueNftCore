pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

import './IndexBasis.sol';

import './interfaces/IData.sol';
import './interfaces/IIndexBasis.sol';

contract NftRoot is DataResolver, IndexResolver {
    uint256 _totalMinted;
    address _addrBasis;

    // Variable to deploy the IndexBasis 
    TvmCell _codeIndexBasis;

    // To limit the tokens amount
    uint64 _tokenLimit;
    mapping (string => uint32) _rarityTypes;
    // To count when tokens are created
    mapping (string => uint32) _rarityCounter;

    constructor(
        TvmCell codeIndex, 
        TvmCell codeData, 
        TvmCell codeIndexBasis,
        uint32 tokenLimit,
        string[] rarityList,
        uint32[] amountsForRarity
    ) public {
        require(rarityList.length == amountsForRarity.length, 111, "The amount of rarity and amounts for it doen't match");

        // TODO: checking the summ of the entered amount of rarity   
        
        tvm.accept();

        _codeIndex = codeIndex;
        _codeData = codeData;
        _codeIndexBasis = codeIndexBasis;
        _tokenLimit = tokenLimit;

        for(uint i = 0; i < rarityList.length; i++) {
            _rarityTypes[rarityList[i]] = amountsForRarity[i];
        }

        deployBasis(_codeIndexBasis);
    }

    function mintNft(
        string rarityType
    ) public {
        require(_rarityTypes.exists(rarityType), 112, "Such tokens there isn't in this collection");
        require(_rarityCounter[rarityType] < _rarityTypes[rarityType], 113, "Tokens of this type cannot be created");

        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        new Data{stateInit: stateData, value: 1.1 ton, bounce: false}(msg.sender, _codeIndex, rarityType);

        _totalMinted++;
        _rarityCounter[rarityType]++;
    }

    function deployBasis(TvmCell codeIndexBasis) public {
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