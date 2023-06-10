## Getting Started

Create a project using this example:

```bash
npx thirdweb create --contract --template hardhat-javascript-starter
```

You can start editing the page by modifying `contracts/Contract.sol`.

To add functionality to your contracts, you can use the `@thirdweb-dev/contracts` package which provides base contracts and extensions to inherit. The package is already installed with this project. Head to our [Contracts Extensions Docs](https://portal.thirdweb.com/contractkit) to learn more.

## Building the project

After any changes to the contract, run:

```bash
npm run build
# or
yarn build
```

to compile your contracts. This will also detect the [Contracts Extensions Docs](https://portal.thirdweb.com/contractkit) detected on your contract.

## Deploying Contracts

When you're ready to deploy your contracts, just run one of the following command to deploy you're contracts:

```bash
npm run deploy
# or
yarn deploy
```

## Releasing Contracts

If you want to release a version of your contracts publicly, you can use one of the followings command:

```bash
npm run release
# or
yarn release
```

## Join our Discord!

For any questions, suggestions, join our discord at [https://discord.gg/thirdweb](https://discord.gg/thirdweb).

# 個別内容

## 1 デプロイ方法

以下のコマンドを実行してください。
```
npx thirdweb deploy
```
thirdwebが立ち上がるため、そのまま処理を実行

## ２ サンプルコード

https://thirdweb.com/mumbai/0x753E053Efee400D49B389E39F7188F412616413a/explorer

## 3 仕様一覧

### 1 問題作成関数 setQyestions

```
function setQyestions(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public  onlyOwner {
        question[_number] = _question;
        answer[_number] = _answer;

        emit QuestionSet(_number, _question, _answer);
    }
```


