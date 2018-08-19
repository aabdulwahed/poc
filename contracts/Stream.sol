pragma solidity ^0.4.24;

contract Stream {

    address public payer;
    address public payee;

    uint256 public startBlock;
    uint256 public closeBlock;
    uint256 public rate;

    event StreamStarted(address payer, address payee, uint256 rate);
    event StreamClosed(address payer, address payee, uint256 funds);

    constructor() public {
        payer = msg.sender;
    }

    /**
     * Modifiers
     */
    modifier onlyPayer() {
        require(msg.sender == payer);
        _;
    }

    modifier onlyInvolvedParties() {
        require(msg.sender == payer || msg.sender == payee);
        _;
    }

    modifier isStreaming() {
        uint256 currentBlock = block.number;
        require(currentBlock >= startBlock && currentBlock <= closeBlock);
        _;
    }

    modifier isNotStreaming() {
        uint256 currentBlock = block.number;
        require((startBlock == 0 && closeBlock == 0) || (currentBlock < startBlock && currentBlock > closeBlock));
        _;
    }

    /**
     * View
     */
    function getCurrentBilling() isStreaming public view returns (uint256) {
        uint256 currentBlock = block.number;
        require(currentBlock >= startBlock);
        return (closeBlock - startBlock) * rate;
    }

    /**
     * State
     */
    function start(address _payee, uint256 _closeBlock, uint256 _rate) onlyPayer public payable {
        payee = _payee;
        startBlock = block.number;
        closeBlock = _closeBlock;
        rate = _rate;
        require((closeBlock - startBlock) * rate == msg.value);
        emit StreamStarted(payer, payee, rate);
    }

    function close() onlyPayer isStreaming public {
        uint256 currentBlock = block.number;

        uint256 funds = (currentBlock - startBlock) * rate;
        payee.transfer(funds);
        startBlock = closeBlock = 0;
        emit StreamClosed(payer, payee, funds);
    }

    /**
     * Destroy
     * This should require signs from both parties
     */
    function kill() public {
        selfdestruct(payer);
    }
}
