pragma solidity ^0.4.24;

contract Stream {

    /**
     * Events
     */
    event StreamStarted(address sender, address recipient, uint256 price, uint256 interval);
    event StreamClosed(address sender, address recipient, uint256 senderFunds, uint256 recipientFunds);

    /**
     * Structs
     */

    struct Timeframe {
        uint256 start;
        uint256 end;
    }

    struct Rate {
        uint256 price;
        uint256 interval;
    }

    /**
     * Storage
     */

    address public sender;
    address public recipient;

    // strong assumptions on block intervals
    Timeframe public timeframe;
    Rate public rate;
    uint256 public funds;

    constructor(address _recipient, uint256 _price, uint256 _interval, uint256 duration) public payable {
        sender = msg.sender;
        recipient = _recipient;

        rate.price = _price;
        rate.interval = _interval;

        // this acts like a pseudo-escrow account, rate needs to be in wei
        funds = (duration / rate.interval) * rate.price;
        require(funds == msg.value);

        // delays could occur here when the network is bloated
        timeframe.start = block.number;
        timeframe.end = timeframe.start + duration;

        emit StreamStarted(sender, recipient, rate.price, rate.interval);
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
        require((timeframe.start == 0 && timeframe.end == 0) || (block.number > timeframe.end));
        _;
    }

    /**
     * View
     */
    function currentBilling() isStreaming public view returns (uint256) {
        require(block.number >= timeframe.start);
        return ((block.number - timeframe.start) / rate.interval) * rate.price;
    }

    /**
     * State Mutations
     */
    function close() onlySender isStreaming public {
        uint256 senderFunds = ((block.number - timeframe.start) / rate.interval) * rate.price;
        sender.transfer(senderFunds);
        timeframe.start = timeframe.end = 0;
        emit StreamClosed(sender, recipient, senderFunds, funds - senderFunds);
    }

    // Recipients cannot currently close the stream while it is active,
    // but this may be amended in the future.
    function redeem() onlyRecipient isNotStreaming public {
        emit StreamClosed(sender, recipient, 0, funds);
        selfdestruct(recipient);
    }
}