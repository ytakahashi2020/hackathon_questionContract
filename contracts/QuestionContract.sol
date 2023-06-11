// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract QuestionContract is Ownable, AccessControl{
    IERC721 public erc721Contract;
    IERC721 public erc721RewardContract;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // 有効投票数
    uint256 validVotesNumber = 3;

    // 投票できるアドレスのリスト
    address[] public whitelistedAddresses;

    // 全コメント数
    uint256 public commentCount;

    // プレゼントカウント
    uint256 public rewardCount = 0;

    // ウォレットアドレス => コメント数
    mapping(address => bool) public isRewardValid;

    // 問題番号 => 問題・解答
    mapping(uint256 => string) public question;
    mapping(uint256 => string) public answer;

    // 問題番号 => コメント数
    mapping(uint256 => uint256) public countByQuestion;

    // コメント番号・インデックス => コメント
    mapping(uint256 =>  mapping(uint256 => string)) public comment;

    // ウォレットアドレス => コメント数
    mapping(address => uint256) public countByAddress;

    // 問題番号 => 投票数
    mapping (uint256 => uint256) public favorNumber;

    // ウォレットアドレス・問題番号　⇨ カウント
    // 問題番号に対して、一人１回まで
    mapping(address =>  mapping(uint256 => uint256)) public userCount;

    // ウォレットアドレス・コメント番号　⇨ コメント
    mapping(address => mapping(uint256 => string)) public commentsByAddress;


    event QuestionSet (
        uint256 indexed _number,
        string question,
        string answer
    );

    event NewComment (
        address indexed from,
        uint256 timestamp,
        string message
    );

    event ValidVote (
        uint256 number
    );

    // 合格証NFTのコントラクトを取得する
    constructor(IERC721 _erc721Contract, IERC721 _erc721RewardContract) {
        erc721Contract = _erc721Contract;
        erc721RewardContract = _erc721RewardContract;
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // 管理者権限を付与する
    function addAdmin(address admin) public onlyOwner {
        _grantRole(ADMIN_ROLE, admin);
    }

    // 合格証NFTの所持数を取得する
    function getErc721Balance(address user) public view returns (uint256) {
        return erc721Contract.balanceOf(user);
    }

    // 問題変更者にお礼のNFTを送付する
    function reward() public {
        require(isRewardValid[msg.sender], "you are not valid");
        erc721RewardContract.safeTransferFrom(address(this), msg.sender, rewardCount);
        rewardCount++;
        isRewardValid[msg.sender] = false;
    }
    
    // ホワイトリストに登録されているか、合格証NFTを持っていればTrue
    function isValidUser(address _user) public view returns (bool) {
        if(isWhitelisted(_user) || getErc721Balance(_user) > 0) {
            return true;
        }
        return false;
    }

    // 問題作成（管理者のみ）
    function setQyestions(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public onlyRole(ADMIN_ROLE) {
        question[_number] = _question;
        answer[_number] = _answer;

        emit QuestionSet(_number, _question, _answer);
    }

    // コメントの作成（誰でも可能）
    function newComment(
        uint256 comment_number,
        string memory _comment
    ) public {
        commentCount++;
        countByQuestion[comment_number]++;
        countByAddress[msg.sender]++;
        comment[comment_number][countByQuestion[comment_number]] = _comment;
        commentsByAddress[msg.sender][countByAddress[msg.sender]] = _comment;

        emit NewComment(msg.sender, block.timestamp, _comment);
    }

    // 投票可能者設定（管理者のみ）
    function whitelistUsers(address[] calldata _users) public onlyRole(ADMIN_ROLE) {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    // 投票可能者の確認
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // 投票実行（ホワイトリスト登録者のみ可能）
    function setFavorNumber (uint256 _number) public {
        require(isValidUser(msg.sender), "user is not valid");
        require(userCount[msg.sender][_number] == 0, "you already set favor");
        favorNumber[_number]++;
        userCount[msg.sender][_number]++;
        // 有効投票数の達した時にイベント発生
        if ( favorNumber[_number] == validVotesNumber ) {
            emit ValidVote(_number);
        }
    }

    // 問題変更（投票者のみ変更可能）
    function changeQyestions(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public {
        require(favorNumber[_number] >= validVotesNumber, "favorNumber is too low");
        require(isValidUser(msg.sender), "user is not valid");
        require(userCount[msg.sender][_number] == 1, "you didn't do favor");
        question[_number] = _question;
        answer[_number] = _answer;
        isRewardValid[msg.sender] = true;
        emit QuestionSet(_number, _question, _answer);
    }
}

