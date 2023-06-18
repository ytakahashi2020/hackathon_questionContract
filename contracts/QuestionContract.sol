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

    // 報酬カウント
    uint256 public rewardCount = 0;

    // 投票できるアドレスのリスト
    address[] public whitelistedAddresses;

    // 問題番号 => 問題・解答
    mapping(uint256 => string) public questionTextByQuestionNumber;
    mapping(uint256 => string) public answerTextByQuestionNumber;

    // 全問題数
    uint256 public questionCount;

    // 全回答数
    uint256 public answerCount;

    // ウォレットアドレス => 報酬受け取り者かの判定
    mapping(address => bool) public isValidRewardAddress;


    /* コメント関連 */

    // 全コメント数
    uint256 public commentCount;

    // 問題番号 => コメント数
    mapping(uint256 => uint256) public commentCountByQuestion;

    // ウォレットアドレス => コメント数
    mapping(address => uint256) public commentCountByAddress;

    // ウォレットアドレス・コメント番号　⇨ コメント
    mapping(address => mapping(uint256 => string)) public commentByAddressForCommentNumber;

    // コメント番号・インデックス => コメント
    mapping(uint256 =>  mapping(uint256 => string)) public indexedCommentForQuestionNumber;


    /* 投票関連 */

    // 問題番号 => 投票数
    mapping (uint256 => uint256) public voteCountForQuestionNumber;

    // ウォレットアドレス・問題番号　⇨ カウント
    mapping(address =>  mapping(uint256 => uint256)) public voteCountByAddressForQuestionNumber;


    /* イベント */
    event QuestionSet (
        uint256 indexed _number,
        string questionTextByQuestionNumber,
        string answerTextByQuestionNumber
    );

    event CommentSet (
        address indexed from,
        uint256 timestamp,
        string message
    );

    event ValidVoteSet (
        uint256 number
    );

    // 全ての問題を取得する
    function getAllQuestions() public view returns (string[] memory) {
        string[] memory questions = new string[](questionCount);
        for (uint i = 0; i < questionCount; i++) {
            questions[i] = questionTextByQuestionNumber[i + 1];
        }
        return questions;
    }

    // 全ての回答を取得する
    function getAllAnswers() public view returns (string[] memory) {
        string[] memory answers = new string[](answerCount);
        for (uint i = 0; i < answerCount; i++) {
            answers[i] = answerTextByQuestionNumber[i + 1];
        }
        return answers;
    }


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
    function requestReward() public {
        require(isValidRewardAddress[msg.sender], "you are not valid");
        erc721RewardContract.safeTransferFrom(address(this), msg.sender, rewardCount);
        rewardCount++;
        isValidRewardAddress[msg.sender] = false;
    }
    
    // ホワイトリストに登録されているか、合格証NFTを持っていればTrue
    function isValidUser(address _user) public view returns (bool) {
        if(isWhitelisted(_user) || getErc721Balance(_user) > 0) {
            return true;
        }
        return false;
    }

    // 問題作成（管理者のみ）
    function setQuestion(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public onlyRole(ADMIN_ROLE) {
        questionTextByQuestionNumber[_number] = _question;
        answerTextByQuestionNumber[_number] = _answer;
        questionCount++;
        answerCount++;

        emit QuestionSet(_number, _question, _answer);
    }

    // コメントの作成（誰でも可能）
    function setCommentForQuestionNumber(
        uint256 comment_number,
        string memory _comment
    ) public {
        commentCount++;
        commentCountByQuestion[comment_number]++;
        commentCountByAddress[msg.sender]++;
        indexedCommentForQuestionNumber[comment_number][commentCountByQuestion[comment_number]] = _comment;
        commentByAddressForCommentNumber[msg.sender][commentCountByAddress[msg.sender]] = _comment;

        emit CommentSet(msg.sender, block.timestamp, _comment);
    }

    // 投票可能者設定（管理者のみ）
    function setWhitelistUsers(address[] calldata _users) public onlyRole(ADMIN_ROLE) {
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
    function submitVoteForQuestionNumber (uint256 _number) public {
        require(isValidUser(msg.sender), "user is not valid");
        require(voteCountByAddressForQuestionNumber[msg.sender][_number] == 0, "you already set favor");
        voteCountForQuestionNumber[_number]++;
        voteCountByAddressForQuestionNumber[msg.sender][_number]++;
        // 有効投票数の達した時にイベント発生
        if ( voteCountForQuestionNumber[_number] == validVotesNumber ) {
            emit ValidVoteSet(_number);
        }
    }

    // 問題変更（投票者のみ変更可能）
    function changeQuestion(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public {
        require(voteCountForQuestionNumber[_number] >= validVotesNumber, "favorNumber is too low");
        require(isValidUser(msg.sender), "user is not valid");
        require(voteCountByAddressForQuestionNumber[msg.sender][_number] == 1, "you didn't do favor");
        questionTextByQuestionNumber[_number] = _question;
        answerTextByQuestionNumber[_number] = _answer;
        isValidRewardAddress[msg.sender] = true;
        emit QuestionSet(_number, _question, _answer);
    }
}

