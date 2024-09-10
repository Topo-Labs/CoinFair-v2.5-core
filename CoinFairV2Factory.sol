
// Mozilla Public License 2.0
pragma solidity =0.5.16;


interface ICoinFairFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB, uint8 poolType) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,uint256 exponentA,uint256 exponentB,uint fee) external returns (address pair);

    function feeToSetter() external view returns (address);
    function setFeeToSetter(address) external;

    function routerAddress() external view returns (address);

    function feeTo() external view returns (address);

    function feeToWeight() external view returns (uint8);
}

interface ICoinFairPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint val ue, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getExponents() external view returns (uint256 exponent0, uint256 exponent1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function getFee() external view returns (uint);
    function getPoolType() external view returns (uint8);
    function setIsPoolFeeOn(uint) external;
    function setRoolOver(bool) external;
    function setDivideParam(uint, uint) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, uint fee ,address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint256, uint256,uint,uint8) external;
}

interface ICoinFairERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract CoinFairERC20 is ICoinFairERC20 {
    using SafeMath for uint;

    string public constant name = 'CoinFair LPs';
    string public constant symbol = 'PE-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    //     require(deadline >= block.timestamp, 'CoinFair: EXPIRED');
    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             '\x19\x01',
    //             DOMAIN_SEPARATOR,
    //             keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
    //         )
    //     );
    //     address recoveredAddress = ecrecover(digest, v, r, s);
    //     require(recoveredAddress != address(0) && recoveredAddress == owner, 'CoinFair: INVALID_SIGNATURE');
    //     _approve(owner, spender, value);
    // }
}

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface ICoinFairCallee {
    function CoinFairCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface ICoinFairNFT {
    function level(address) external view returns (uint256);
    function getTwoParentAddress(address sonAddress) external view returns(address, address);
}

// Generally, token0 and token1 are ordered, and tokenA and tokenB are unordered
contract CoinFairPair is ICoinFairPair, CoinFairERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    address public CoinFairNFT = 0x70b304e75A467aa580148e4fA1a4f954dfC5748e;
    uint256 public exponent0;
    uint256 public exponent1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0^exponent0 * reserve1^exponent1, as of immediately after the most recent liquidity event
    
    uint public fee;
    
    uint public feeToParent = 300;
    uint public feeToGrandParent = 100;
    uint8 public poolType;
    // default no liquidityfee
    uint public isPoolFeeOn;
    // default not rool over
    bool public roolOver;
    
    uint private constant pow128 = 2 ** 128;
    uint private constant pow64 = 2 ** 64;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'CoinFair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    function setIsPoolFeeOn(uint _isPoolFeeOn)public {
        require(msg.sender == ICoinFairFactory(factory).feeTo(),'CoinFair : REFUSE');
        isPoolFeeOn = _isPoolFeeOn;
    }

    function setRoolOver(bool _roolOver)public {
        require(msg.sender == ICoinFairFactory(factory).feeTo(),'CoinFair : REFUSE');
        roolOver = _roolOver;
    }

    function setDivideParam(uint _feeToParent, uint _feeToGrandParent)public {
        require(msg.sender == ICoinFairFactory(factory).feeTo(),'CoinFair : REFUSE');
        require(_feeToParent.add(_feeToGrandParent) < 1000);
        feeToParent = _feeToParent;
        feeToGrandParent = _feeToGrandParent;
    }

    function getFee() public view returns (uint){
        return fee;
    }

    function getPoolType() public view returns (uint8){
        return poolType;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getExponents() public view returns (uint256 _exponent0, uint256 _exponent1, uint32 _blockTimestampLast) {
        _exponent0 = exponent0;
        _exponent1 = exponent1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CoinFair: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint256 _exponent0, uint256 _exponent1,uint _fee,uint8 _poolType) external {
        require(msg.sender == factory, 'CoinFair: FORBIDDEN'); // sufficient check
        require(_fee == 3 || _fee == 5 || _fee == 10, "ERROR FEE");
        require(_token0 != address(0) && _token1 != address(0));
        token0 = _token0;
        token1 = _token1;
        exponent0 = _exponent0;
        exponent1 = _exponent1;
        fee = _fee;
        poolType = _poolType;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'CoinFair: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to x/30 of the growth in sqrt(k)
    // When the pool is added/removed, the liquidity rewards accumulated previously will be transferred to a fund account through lptoken
    // kLast：The K after the last liquidity addition is compared with the current K, so we can know how much the increased service charge is
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        uint8 feeToWeight = ICoinFairFactory(factory).feeToWeight();
        
        feeOn = feeToWeight * isPoolFeeOn > 0;
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(exp(_reserve0, exponent0, 32)).mul(exp(_reserve1, exponent1, 32)));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint8 leftWeight = 30 - feeToWeight;
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(feeToWeight);
                    uint denominator = rootK.mul(leftWeight).add(rootKLast.mul(feeToWeight));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) {
                        _mint(ICoinFairFactory(factory).feeTo(), liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    // According to the proportion of new tokens (rounded down), the new lptoken of mint is given to to
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'CoinFair: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(exp(reserve0, exponent0, 32)).mul(exp(reserve1, exponent1, 32));  // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // According to the proportion of newly added tokens (rounded down), the service charge of the fund account will be disposed of each time the mint new lptoken gives to the to liquidity, and the rest
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'CoinFair: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(exp(reserve0, exponent0, 32)).mul(exp(reserve1, exponent1, 32)); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt_new(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log_2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        //unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        //}
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log_2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        //unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        //}
        return result;
    }

    function gcd(uint256 a, uint256 b) internal pure returns (uint256) {
        while (b > 0) {
            uint256 temp=b;
            b = a%b;
            a = temp;
        }
        return a;
    }

    // Calculate the a/b power of n
    function exp(uint256 n, uint256 a, uint256 b) public pure returns (uint256) {
        if (a == b) {
            return n;
        }
        uint256 g = gcd(a, b);
        a = a/g;
        b = b/g;
        if(a==1 && b == 4){
            return sqrt_new(sqrt_new( n * pow128) * pow64);
        }

        if(a ==4 && b ==1){
             return n * n  / pow64 * n / pow64 * n / pow128;
        }

        if(a == 1 && b == 32){
            return sqrt_new(sqrt_new(sqrt_new(sqrt_new(sqrt_new(n * pow128) * pow64) * pow64) * pow64) * pow64);
        }

        if(a == 32 && b == 1){
            uint q = n * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            return q * n / pow128;
        }

        return n;
    }
    
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, uint fee_ ,address to, bytes calldata data) external lock {
        require(msg.sender == ICoinFairFactory(factory).routerAddress(), 'not router');
        require(amount0Out > 0 || amount1Out > 0, 'CoinFair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'CoinFair: INSUFFICIENT_LIQUIDITY');

        (uint balance0, uint balance1) = _swapAssist(to, amount0Out, amount1Out, fee_, data);
        // Calculate the complete input amount
        // uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        // uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(( balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0) > 0 || (balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0) > 0, 'CoinFair: INSUFFICIENT_INPUT_AMOUNT');
        
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        require(exp(balance0, exponent0, 32).mul(exp(balance1, exponent1, 32)) >= 
            exp(_reserve0, exponent0, 32).mul(exp(_reserve1, exponent1, 32)), 'CoinFair: K');
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0, balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0, amount0Out, amount1Out, to);
    }

    function _swapAssist(address to, uint amount0Out, uint amount1Out, uint fee_, bytes memory data)internal returns(uint,uint){
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'CoinFair: INVALID_TO');
        (address parentAddr, address grandParentAddr) = ICoinFairNFT(CoinFairNFT).getTwoParentAddress(msg.sender);

        // pay fee
        if(exponent0 == 32 && exponent1 == 32 && roolOver){
            if(feeToParent != 0 && parentAddr != address(0)){
                exponent0 < exponent1 ?
                    _safeTransfer(_token1, parentAddr, fee_ * 1000 * feeToParent / 1000000) :
                    _safeTransfer(_token0, parentAddr, fee_ * 1000 * feeToParent / 1000000);
            }

            if(feeToGrandParent != 0 && grandParentAddr != address(0)){
                exponent0 < exponent1 ?
                    _safeTransfer(_token1, grandParentAddr, fee_ * 1000 * feeToGrandParent / 1000000) :
                    _safeTransfer(_token0, grandParentAddr, fee_ * 1000 * feeToGrandParent / 1000000);
            }

            uint feeLeft = fee_.sub(fee_ * 1000 * feeToParent / 1000000).sub(fee_ * 1000 * feeToGrandParent / 1000000);
            
            if(feeLeft > 0 && ICoinFairFactory(factory).feeTo() != address(0)){
                exponent0 < exponent1 ? 
                    _safeTransfer(_token1, ICoinFairFactory(factory).feeTo(),feeLeft) :
                    _safeTransfer(_token0, ICoinFairFactory(factory).feeTo(),feeLeft); 
            }
        }else{
            if(feeToParent != 0 && parentAddr != address(0)){
                exponent0 < exponent1 ?
                    _safeTransfer(_token0, parentAddr, fee_ * 1000 * feeToParent / 1000000) :
                    _safeTransfer(_token1, parentAddr, fee_ * 1000 * feeToParent / 1000000);
            }

            if(feeToGrandParent != 0 && grandParentAddr != address(0)){
                exponent0 < exponent1 ?
                    _safeTransfer(_token0, grandParentAddr, fee_ * 1000 * feeToGrandParent / 1000000) :
                    _safeTransfer(_token1, grandParentAddr, fee_ * 1000 * feeToGrandParent / 1000000);
            }

            uint feeLeft = fee_.sub(fee_ * 1000 * feeToParent / 1000000).sub(fee_ * 1000 * feeToGrandParent / 1000000);
            
            if(feeLeft > 0 && ICoinFairFactory(factory).feeTo() != address(0)){
                exponent0 < exponent1 ? 
                    _safeTransfer(_token0, ICoinFairFactory(factory).feeTo(),feeLeft) :
                    _safeTransfer(_token1, ICoinFairFactory(factory).feeTo(),feeLeft); 
            }
        }

        if (amount0Out > 0)  _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0)  _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        if (data.length > 0) ICoinFairCallee(to).CoinFairCall(msg.sender, amount0Out, amount1Out, data);
        return (IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)));
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

contract CoinFairFactory is ICoinFairFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(CoinFairPair).creationCode));
    
    address public feeToSetter;
    address public feeTo;
    uint8 public feeToWeight;
    address public routerAddress;

    address public WETH;

    mapping(address => mapping(address => mapping(uint8 => address))) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint length, uint fee);


    constructor() public {
        feeToSetter = msg.sender;
        feeTo = 0xEE89C7d5B07f163b613a7941eD4d1446FF0d6709;
        feeToWeight = 0;

        WETH = 0x4200000000000000000000000000000000000006;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB,uint256 exponentA,uint256 exponentB,uint fee) external returns (address pair) {
        require(tokenA != tokenB, 'CoinFair: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint256 exponent0, uint256 exponent1) = tokenA < tokenB ? (exponentA, exponentB) : (exponentB, exponentA);
        require(token0 != address(0), 'CoinFair: ZERO_ADDRESS');

        uint8 poolType;
        if(exponentA == 32 && exponentB == 32){poolType=1;}
        else if (exponentA == 32 && exponentB == 8){poolType = 2;}
        else if (exponentA == 8 && exponentB == 32){poolType = 3;}
        else if (exponentA == 32 && exponentB == 1){poolType = 4;}
        else if (exponentA == 1 && exponentB == 32){poolType = 5;}

        require(getPair[token0][token1][poolType] == address(0), 'CoinFair: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(CoinFairPair).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(token0, token1, poolType));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        ICoinFairPair(pair).initialize(token0, token1, exponent0, exponent1,fee,poolType);
        getPair[token0][token1][poolType] = pair;
        getPair[token1][token0][poolType] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length,fee);
    }


    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(_feeToSetter != address(0));
        feeToSetter = _feeToSetter;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(_feeTo != address(0));
        feeTo = _feeTo;
    }

    function setFeeToWeight(uint8 _feeToWeight) external {
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(_feeToWeight <= 30, 'Weight is too big to set');
        feeToWeight = _feeToWeight;
    }

    function setRouterAddress(address _routerAddress) external {
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(_routerAddress != address(0));
        routerAddress = _routerAddress;
    }

    // There is no need to consider the order of tokenA and tokenB
    function setIsPoolFeeOn(address tokenA, address tokenB, uint8 poolType, uint _isPoolFeeOn) external{
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(_isPoolFeeOn <= 1 && getPair[tokenA][tokenB][poolType] != address(0));
        ICoinFairPair(getPair[tokenA][tokenB][poolType]).setIsPoolFeeOn(_isPoolFeeOn);
    }

    // There is no need to consider the order of tokenA and tokenB
    function setRoolOver(address tokenA, address tokenB, bool _roolOver) external{
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(getPair[tokenA][tokenB][1] != address(0));
        ICoinFairPair(getPair[tokenA][tokenB][1]).setRoolOver(_roolOver);
    }
    
    // There is no need to consider the order of tokenA and tokenB
    function setDivideParam(address tokenA, address tokenB, uint8 poolType, uint _feeToParent, uint _feeToGrandParent) external{
        require(msg.sender == feeToSetter, 'CoinFair: FORBIDDEN');
        require(getPair[tokenA][tokenB][poolType] != address(0));
        
        ICoinFairPair(getPair[tokenA][tokenB][poolType]).setDivideParam(_feeToParent, _feeToGrandParent);
    }

}


