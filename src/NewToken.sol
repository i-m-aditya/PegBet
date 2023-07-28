

contract NewToken is ERC1155 {
    uint256 public constant GOLD = 0;
    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _mint(msg.sender, GOLD, 10**18, "");
    }
}