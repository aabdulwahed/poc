pragma solidity ^0.4.24;

contract Stream {

    struct Timeframe {
        uint256 start;
        uint256 end;
    }

    address public sender;
    address public recipient;

    // strong assumptions on block intervals
    Timeframe public timeframe;

    // implied time unit is 1 block
    uint256 public rate;
    uint256 public funds;

    event StreamStarted(address sender, address recipient, uint256 rate);
    event StreamClosed(address sender, address recipient, uint256 senderFunds, uint256 recipientFunds);

    constructor(address _recipient, uint256 _rate, uint256 duration) public payable {
        sender = msg.sender;
        recipient = _recipient;
        rate = _rate;

        // this acts like a pseudo-escrow account, rate needs to be in wei
        funds = duration * rate;
        require(funds == msg.value);

        // delays could occur here when the network is bloated
        timeframe.start = block.number;
        timeframe.end = timeframe.start + duration;

        emit StreamStarted(sender, recipient, rate);
    }

    /**
     * Modifiers
     */
    modifier onlySender() {
        require(msg.sender == sender);
        _;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient);
        _;
    }

    modifier onlyInvolvedParties() {
        require(msg.sender == sender || msg.sender == recipient);
        _;
    }

    modifier isStreaming() {
        require(block.number >= timeframe.start && block.number <= timeframe.end);
        _;
    }

    modifier isNotStreaming() {
        // stream is either deactivated or ongoing
        require((timeframe.start == 0 && timeframe.end == 0) || (block.number < timeframe.start && block.number > timeframe.end));
        _;
    }

    /**
     * View
     */
    function currentBilling() isStreaming public view returns (uint256) {
        require(block.number >= timeframe.start);
        return (block.number - timeframe.start) * rate;
    }

    /**
     * State
     */
    function close() onlySender isStreaming public {
        uint256 senderFunds = (block.number - timeframe.start) * rate;
        sender.transfer(senderFunds);
        timeframe.start = timeframe.end = 0;
        emit StreamClosed(sender, recipient, senderFunds, funds - senderFunds);
    }

    /**
     * Recipients cannot currently close the stream while it is active,
     * but this may be amended in the future.
     */
    function redeem() onlyRecipient isNotStreaming public {
        emit StreamClosed(sender, recipient, 0, funds);
        selfdestruct(recipient);
    }
}