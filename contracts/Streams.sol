pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";

/**
 * Structs
 */

contract Streams is Ownable {
    using SafeMath for uint256;

    /**
     * Events
     */

    event StreamStarted(address payer, address payee);
    event StreamClosed(address payer, address payee);
    event StreamRedeemed(address payer, address payee);

    /**
     * Structs
     */
     
    // strong assumptions on block intervals
    struct Timeframe {
        uint256 start;
        uint256 close;
    }

    struct Rate {
        uint256 price;
        uint256 interval;
    }
    
    struct Stream {
        StreamState state;
        address payer;
        address payee;
        uint256 balance;
        Timeframe timeframe;
        Rate rate;
    }
    
    /**
     * Enums
     */
    enum StreamState { NonExistent, Streaming, NonStreaming, Finalized }

    /**
     * Storage
     */
    uint256 public streamNonce;
    mapping (uint256 => Stream) public streams;

    constructor() 
        public 
    {
        streamNonce = 1;
    }

    /**
     * Modifiers
     */
    modifier isStreaming(uint256 id) 
    {
        // make sure that the state is indeed `.Streaming` when it should be
        Stream memory stream = streams[id];
        if (stream.state != StreamState.Streaming && block.number >= stream.timeframe.start && block.number <= stream.timeframe.close) {
            streams[id].state = StreamState.Streaming;
        }
        require(stream.state == StreamState.Streaming, "stream must be active");
        _;
    }
    
    modifier isNonStreaming(uint256 id)
    {
        // make sure that the state is indeed `.NonStreaming` when it should be
        Stream memory stream = streams[id];
        if (stream.state != StreamState.NonStreaming && block.number >= stream.timeframe.close) {
            streams[id].state = StreamState.NonStreaming;
        }
        require(stream.state == StreamState.NonStreaming, "stream must not be active");
        _;
    }
    
    modifier isNonNilStream(uint256 id)
    {
        require(id < streamNonce, "id is incorrect");
        //require(streams[streamId] != nil); // gotta research what nil is in solidity
        _;
    }
    
    modifier onlyPayer(uint256 id) {
        require(streams[id].payer == msg.sender, "only the payer can call this function");
        _;
    }
    
    modifier onlyPayee(uint256 id) {
        require(streams[id].payee == msg.sender, "only the payee can call this function");
        _;
    }
    
    /**
     * Functions
     */
     
    // @param streamId      the id of the stream
    function currentBilling(uint256 id)
        isNonNilStream(id)
        isStreaming(id)
        public
        returns (uint256 billing)
    {

        // p * ((c - s) / i)
        Stream memory stream = streams[id];
        return ((block.number - stream.timeframe.start) / stream.rate.interval) * stream.rate.price;
    }
    
    // @param id      the id of the stream
    function stateOf(uint256 id)
        isNonNilStream(id)
        public
        view
        returns (StreamState state)
    {
        // Stream memory stream = streams[id];
        // if (block.number > stream.timeframe.close) {
        //     streams[id].state = stream.balance > 0 ? StreamState.NonStreaming : StreamState.Finalized;
        // }
        return streams[id].state;
    }
    
    // Creates a stream
    //
    // @param payee         the account receiving the payments
    // @param startBlock    start of the stream
    // @param closeBlock    close of the stream
    // @param price         how much the payers pays per interval
    // @param interval      the rate at which $price worth of ㆔ is streamed
    function startStream(address payee, uint256 startBlock, uint256 closeBlock, uint256 price, uint256 interval)
        public
        payable
    {
        require(startBlock >= block.number, "The starting block needs to be higher than the current block number");
        
        uint256 duration = closeBlock - startBlock;
        require(duration >= 1, "The closing block needs to be higher than the starting block");
        require(duration >= interval, "The total stream duration needs to be higher than the payment interval");
       
        uint256 funds = (duration / interval) * price;
        require(funds == msg.value, "Funds need to be deposited beforehand by the payer");
        
        address payer = msg.sender;
        streams[streamNonce] = Stream(
            StreamState.Streaming,
            payer,
            payee,
            msg.value,
            Timeframe(startBlock, closeBlock),
            Rate(price, interval)
        );
        emit StreamStarted(payer, payee);
        
        streamNonce = streamNonce.add(1);
    }
    
    // Closes a stream
    //
    // @param id        The id of the stream
    function closeStream(uint256 id)
        isNonNilStream(id)
        public
    {
        Stream memory stream = streams[id];
        emit StreamClosed(stream.payer, stream.payee);
        
        // strong assumptions on tx processing speeds and economics
        uint256 remainder = ((block.number - stream.timeframe.start) / stream.rate.interval) * stream.rate.price;
        stream.payer.transfer(remainder);
        streams[id].state = StreamState.NonStreaming;
    }
    
    // Recipients cannot currently close the stream while it is active,
    // but this may be amended in the future.
    //
    // @param id        The id of the stream
    function redeem(uint256 id) 
        onlyPayee(id)
        isNonNilStream(id)
        isNonStreaming(id)
        public 
    {
        Stream memory stream = streams[id];
        msg.sender.transfer(stream.balance);
        emit StreamRedeemed(stream.payer, stream.payee);

        streams[id].balance = 0;
        streams[id].state = StreamState.Finalized;
    }
}