# CoinFair-v2.5-合约文档

## 最新合约地址&abi

- CoinFairHotRouter：
  - 0xE2D17b6F9B3Ad3c3E45c8948353d2093A7bAA059

- CoinFairWarmRouter：
  - 0xb533fDe269e64D0C3e06211ac7BeDeFAd01E64E6

- Factory：
  - 0xb229E3026eE90C3AFC07ce418392244fBcCcfb6A

- Initcode：
  - 0xe926172bbeaf728f971d4ac518828df3e6f99af1d7e1f571c0ab18270ae16d28

- CoinFairTreasury：
  - 0x6CDe00FA36edf0D051BfEE7a0Dde519047C70C1f

- CoinFairNFT：
  - 0x7684f094CDCF13Ad72D9252D6779487e5f0dFC3e

- abi
  - https://github.com/Topo-Labs/CoinFair-v2.5-core



更新时间：9-25 5:00



## 合约结构&关键函数

- `CoinFairV2Treasury`：国库

  - `collectFee`：收集手续费
  - `withdrawFee(address token)`：领取手续费
  - `CoinFairUsrTreasury[owner][token]`：查询待领取手续费余额
  - `lockLP(address pair, uint256 amount, uint256 time)`：锁仓
  - `releaseLP(address pair)`：解锁
  - `getBestPool(address[] memory path, uint amount, bool isExactTokensForTokens)`：获取两个token的兑换中，在指定的amount和兑换方向下，最优的poolType和fee
  - `getPairManagement(address[] memory path)`：获取用户在两个token形成的所有pair中，拥有的流动性

- `CoinFairFactory`：工厂

  - `getPair[tokenA][tokenB][poolType][fee]`：获取pair地址
    - `poolType` = 1/2/3/4/5
    - `fee` = 1/3/5/10

- `CoinFairHotRouter`：热路由，完成与swap相关的路由

  - `swapExactTokensForTokens`
  - `swapTokensForExactTokens`
  - `swapExactETHForTokens`
  - `swapTokensForExactETH`
  - `swapExactTokensForETH`
  - `swapETHForExactTokens`
  - `swapExactTokensForTokensSupportingFeeOnTransferTokens`
  - `swapExactETHForTokensSupportingFeeOnTransferTokens`
  - `swapExactTokensForETHSupportingFeeOnTransferTokens`

- `CoinFairWarmRouter`：暖路由，完成与流动性相关的路由

  - `addLiquidity`
  - `addLiquidityETH`
  - `removeLiquidity`
  - `removeLiquidityETH`
  - `removeLiquidityETHSupportingFeeOnTransferTokens`

  ```
  🔴 CoinFairHotRouter和CoinFairWarmRouter的授权需要分别检查
  ```

- `CoinFairNFT`：NFT



## CoinFairV2Treasury

- `getBestPool`：在`tokenA`和`tokenB`组成的20个池子中，选择能兑换出最多代币的最优池子
  - input：
    - `address[] memory path`：`[tokenA, tokenB]`，只能两个代币
    -  `uint amount`：输入数量
    -  `bool isExactTokensForTokens`
      - `true`：`ExactTokensForTokens`
      - `false`：`TokensForExactTokens`
      - 具体是哪种可以参考接下来要调用的函数时`ExactTokensForTokens`还是`TokensForExactTokens`。
  - output：
    - `uint8 bestPoolType`：最优池子的类型
    - `uint bestfee`：最优池子的手续费
    - `uint finalAmount`：最优池子能兑换出的数量

```
🔴在执行swap时，首选获取用户输入的tokenA和tokenB

- 假设未开启多跳
调用getBestPool获取tokenA和tokenB的最佳池子，执行swap操作
tokenA -- tokenB

- 假设开启多跳，如多跳代币为eth和usdt
前端首先计算多种可能的路径
tokenA -- tokenB
tokenA -- usdt -- tokenB
tokenA -- eth -- tokenB
tokenA -- eth -- usdt -- tokenB
tokenA -- usdt -- eth -- tokenB

以tokenA -- eth -- usdt -- tokenB为例，分别调用getBestPool获取两两代币间的最佳池子，组合成一个确定的路径
即三个数组 address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath
在此例中为：path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10]
path长度比poolTypePath和feePath长1
执行swap操作


// TODO：getBestPool的计算上有一些可以优化
```



- `getPairManagement`：在流动性管理时，获取用户在指定两个代币下所有的pair地址和余额

  - input

    - `address[] memory path`：`[tokenA, tokenB]`，只能两个代币
    - `address usrAddr`:  用户地址

  - output：

    - `usrPoolManagement[] memory UsrPoolManagement`：用户所有的流动性

  - ```solidity
        // 输出的结构体，用户的一组流动性数据由pair和lptoken数量组成
        struct usrPoolManagement{
        		// pair的地址
            address usrPair;
            // 用户持有的lp代币数量
            uint256 usrBal;
        }
    ```

```
🔴在导入用户的流动性数据时，用户先输入两个币[tokenA, tokenB]，通过getPairManagement函数获取用户拥有的，在tokenA和tokenB中所组成的pair中的所有流动性的数据。如返回多个，可允许用户选择导入哪一个（此时要展示每一个的usrBal），再根据用户的选择导入pair进行流动性管理
```



- `withdrawFee`：领取用户在国库中累积的指定代币的待领取手续费

  - input
    - `address token`：指定要领取的手续费的代币
  - output

- `CoinFairUsrTreasury`：查询任意用户在国库中累积的指定代币的待领取手续费的余额

  - input

    - `address owner`：用户地址
    - `address token`：代币地址

  - output

    - `uint256 amount`：数额

    ```
    🔴领取手续费界面，首先应列出几个常见的手续费代币，用于快速查看和领取。前端在用户刷新/请求网站的时候获取这些余额并展示。同时也提供了一个输入框，供用户输入合约地址查询不常见的手续费代币的累积余额，查询时调用CoinFairUsrTreasury[owner][token],owner传入用户自己的地址，token传入用户输入的代币的地址。查询后如果余额大于0，右侧领取亮起供用户调用withdrawFee领取自己的反佣手续费。
    ```

    

## CoinFairWarmRouter

- `addLiquidity`

  - input

    - `address tokenA,`

    - `address tokenB,`

    - `address to,`

    - `uint deadline,`

    - `bytes calldata addLiquidityCmd`

      - ```solidity
        addLiquidityCmd = abi.encode(uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,uint8 swapN,uint fee);
        ```

        - `uint amountADesired,`

        - `uint amountBDesired,`

        - `uint amountAMin,`

        - `uint amountBMin,`

        - `uint8 swapN,`

          ```
          🔴对于两个token的流动性，swapN只会等于1/2/4。如果token和eth的流动性，才会出现1/2/3/4/5
          ```

        - `uint fee`

  - output

    - `uint amountA,`
    - `uint amountB,`
    - `uint liquidity`

- `addLiquidityETH`

  - Input：

    - `address token,`

    - `bytes calldata addLiquidityETHCmd,`

    - ```solidity
      addLiquidityETHCmd = abi.encode(uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,uint8 swapN)
      ```

      - `uint amountTokenDesired,`
      - `uint amountTokenMin,`
      - `uint amountETHMin,`
      - `uint8 swapN`

    - `address token,`

    - `address to,`

    - `uint deadline,`

    - `uint fee`

  - output：

    - `uint amountToken,`
    - `uint amountETH,` 
    - `uint liquidity`

- ​    `removeLiquidity`

  （同`removeLiquidityETH` / `removeLiquidityETHSupportingFeeOnTransferTokens`）

  - input：
    - `address tokenA`
    - `address tokenB`
    - `uint liquidity`
    - `uint amountAMin`
    - `uint amountBMin`
    - `address to`
    - `uint deadline`
    - `uint8 poolType`
    - `uint fee`
  - output
    - `uint amountA`
    - `uint amountB`

## CoinFairFactory

- `getPair[tokenA][tokenB][poolType][fee]`：获取pair地址

  - input：

    - `address tokenA`：tokenA地址

    - `address tokenB`：tokenB地址（和tokenA地址不分先后顺序）

    - `uint8 poolType`：池子类型，expoentA和exponentB和poolType强相关。一般来说，poolType为1/2/3/4/5，1对应ESIII，2/3对应ESI，4/5对应ESII

      ```solidity
              if(exponentA == 32 && exponentB == 32){poolType = 1;}
              else if (exponentA == 32 && exponentB == 8){poolType = 2;}
              else if (exponentA == 8 && exponentB == 32){poolType = 3;}
              else if (exponentA == 32 && exponentB == 1){poolType = 4;}
              else if (exponentA == 1 && exponentB == 32){poolType = 5;}
      ```

    - `uint fee`：手续费类型，1/3/5/10



## CoinFairHotRouter

- `swapETHForExactTokens`

  同其他swap函数

  - input

    - `uint amountOut`
    - `address[] calldata path`：兑换的代币路径
    - `uint8[] calldata poolTypePath`：兑换的池子类型路径
    - `uint[] calldata feePath`：兑换的手续费路径
    - `address to`
    - `uint deadline`

    ```
    🔴如path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10]，poolTypePath[0] = 2是tokenA和eth所组成池子的池子类型，feePath[0] = 3是tokenA和eth所组成池子的手续费，即四个币会两两组成三个池子。
    ```

  - output：

    - `uint[] memory amounts`

## CoinFairNFT
