/// SPDX-License-Identifier: MIT
/** 
*    References: 
*        https://github.com/nibbstack/erc721/blob/master/src/contracts/tokens/nf-token.sol
*        https://ethereum.org/pt-br/developers/docs/standards/tokens/erc-721/#body
*        https://eips.ethereum.org/EIPS/eip-721#motivation
*/ 
pragma solidity ^0.8.0;

import "./SupportsInterface.sol";
import "./utils/erc721.sol";
import "./utils/erc721-token-receiver.sol";

/// @title Mecha NFT Collection
/// @notice Mecha NFTs that contain random attributes
contract Mecha is 
    ERC721,
    SupportsInterface
{
    /**
    * @dev Magic value of a smart contract that can receive NFT.
    * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
    */
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;


    /// @notice Attributes ment to give different aspects to a Mecha, the higher the better
    /// @param strength The strenght of the Mecha
    /// @param health The health of the Mecha
    /// @param speed The speed of the Mecha
    struct MechaAttributes {
        uint8 strength;
        uint8 health;
        uint8 speed;
    }

    uint256 private _nextTokenId = 1;
    uint256 public constant MINT_PRICE = 0.001 ether;

    /// @dev A mapping from NFT ID to the address that owns it.
    mapping (uint256 => address) internal idToOwner;

    /// @dev Mapping from NFT ID to approved address.
    mapping (uint256 => address) internal idToApproval;

    /// @dev Mapping from owner address to count of their tokens.
    mapping (address => uint256) private ownerToNFTokenCount;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /// @dev Mapping from Mecha id to MechaAttributes
    mapping (uint256 => MechaAttributes) internal idToAttributes;

    /// @dev Contract constructor.
    constructor() {
        /// 0x80ac58cd = ERC721
        supportedInterfaces[0x80ac58cd] = true;
    }

    /// @notice Emitted when ownership of an NFT changes
    /// @dev Required by the ERC-721 specification.
    /// @param _from Source address (address(0) if minting)
    /// @param _to Destination address (address(0) if burning)
    /// @param _tokenId ID of the transferred token
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 indexed _tokenId
    );

    /// @notice Emitted when an address is granted permission to operate a specific NFT
    /// @dev Required by the ERC-721 specification.
    /// @param _owner Current owner of the NFT
    /// @param _approved Address that received approval (or address(0) to remove)
    /// @param _tokenId ID of the approved token
    event Approval(
        address indexed _owner, 
        address indexed _approved, 
        uint256 indexed _tokenId
    );

    /// @notice Emitted when an operator is approved or unapproved to manage all NFTs of an owner
    /// @dev Required by the ERC-721 specification.
    /// @param _owner Owner of the NFTs
    /// @param _operator Address of the operator
    /// @param _approved True to grant permission, false to revoke
    event ApprovalForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
    );

    error InvalidNewOwner(address invalidNewOwner);
    error InvalidAddress(address invalidAddress);
    error InvalidOwner(address invalidOwner);

    /**
    * @dev Guarantees that the msg.sender is allowed to transfer NFT.
    * @param _tokenId ID of the NFT to transfer.
    */
    modifier canTransfer(uint256 _tokenId) {
        address _owner = idToOwner[_tokenId];
        require(
            msg.sender == _owner
            || msg.sender == idToApproval[_tokenId]
            || ownerToOperators[_owner][msg.sender],
            "Not owner, approved or operator"
        );
        _;
    }

    /**
    * @dev Guarantees that _tokenId is a valid Token.
    * @param _tokenId ID of the NFT to validate.
    */
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "NFT no valid");
        _;
    }

    /**
    * @notice The actual transfers are made from this function, in order
    *   to centralize logic and reduce bugs. Thus, no need for modifiers related to
    *   transferences in logics that call _transfer()
    * @dev Actually performs the transfer.
    * @param _from Address of the current owner.
    * @param _to Address of a new owner.
    * @param _tokenId The NFT that is being transferred.
    */
    function _transfer (
        address _from, 
        address _to, 
        uint256 _tokenId
    ) 
        private
        canTransfer(_tokenId)
        validNFToken(_tokenId) 
    {
        address _owner = idToOwner[_tokenId];
        if (_from != _owner) revert InvalidOwner(_owner);
        if (_to == address(0)) revert InvalidNewOwner(_to);
        
        // updates ownership
        idToOwner[_tokenId] = _to;
        
        // updates ntf counters
        ownerToNFTokenCount[_from] -= 1;
        ownerToNFTokenCount[_to] += 1;

        delete idToApproval[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev Actually perform the safeTransferFrom.
    * @param _from The current owner of the NFT.
    * @param _to The new owner.
    * @param _tokenId The NFT to transfer.
    * @param _data Additional data with no specified format, sent in call to `_to`.
    */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        private
    {
        _transfer(_from, _to, _tokenId);

        if (_to.isContract())
        {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    /**
    * @notice Throws if _owner is equal to zero address
    * @dev Get the amount of NFTs an address has
    * @param _owner The owner address
    * @return uint256 The amount of NFTs the address owns
    */
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert InvalidAddress(_owner);
        return ownerToNFTokenCount[_owner];
    }

    /**
    * @dev Get the address of a token's owner
    * @param _tokenId The token Id
    * @return address Token owner address
    */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        if(_owner != address(0)) revert InvalidOwner(_owner);
    }

    /**
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes data
    ) 
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /**
    * @notice Transfers the ownership of an NFT from one address to another address
    * @dev This works identically to the other function with an extra data parameter,
    *  except this function just sets data to "".
    * @param _from The current owner of the NFT
    * @param _to The new owner
    * @param _tokenId The NFT to transfer
    */
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) 
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
    * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
    * they may be permanently lost.
    * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
    * address. Throws if `_tokenId` is not a valid NFT.
    * @param _from The current owner of the NFT.
    * @param _to The new owner.
    * @param _tokenId The NFT to transfer.
    */
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) 
        external 
        canTransfer(_tokenId) 
        validNFToken(_tokenId) 
    {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

}