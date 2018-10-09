pragma solidity ^0.4.24;


contract TokenERC20 {

    // @_owner  address du createur du contract
    address public owner;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;

    // Prices of the token
    uint256 public sellPrice;
    uint256 public buyPrice;

    // This creates an array with all balances
    mapping (address => uint256) balanceOf;

    // Distributeur ==W> Echange coin et cfa
    mapping (address => bool) isDistributor;
    uint256 public distributorCount;

    // Retryer without account
    struct Operator {
        string nom;
        string prenom;
        string cin;
    }

    struct Transaction {
        Operator sender;
        uint256 amount;
        bool retrait;
    }

    // Transaction de retrait
    mapping (address => mapping(string => Transaction)) public wari;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //  Constructeur du Token
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    //Condition : owner  only
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * Transfer tokens from msg.sender to another address
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function wariAccount(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from msg.sender to the Network
     * @param _nom The first name of Operator
     * @param _prenom The last name of Operator
     * @param _cin The CIN of Operator
     * @param _amount the amount that msg.sender send to Operator
     * @param _secret the password of the transaction
     */
    function wariNode(string _nom, string _prenom, string _cin, uint256 _amount, string _secret)
    public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount);

        Operator memory recever;
        recever.nom = _nom;
        recever.prenom = _prenom;
        recever.cin = _cin;

        Transaction memory envoi;
        envoi.sender = recever;
        envoi.amount = _amount;
        envoi.retrait = false;

        wari[msg.sender][_secret] = envoi;
        return true;
    }

    /**
     *  Operator : Get cash cfa of transaction
     *  @param _sender the address of sender
     *  @param _secret the password of the transaction
     */
    function cashNode(address _sender, string _secret) public returns (bool success) {
        require(isDistributor[msg.sender] == true);
        Transaction memory envoi = wari[_sender][_secret];

        if (envoi.retrait == false) {
            wari[_sender][_secret].retrait = true;
            _transfer(_sender, this, envoi.amount);
            _transfer(this, msg.sender, envoi.amount / 10);
            return true;
        }
    }

    /**
     *  Distributor : Get cash cfa of transaction
     *  @param _address the address of Distributor
     *  @param _amount value of cash cfa
     */
    function cashService(address _address, uint256 _amount)
    public onlyOwner returns (bool success) {
        _transfer(_address, this, _amount);
    }

    /**
     * allow to use cashNode
     * @param _address The address to allow
    */
    function addDistributor(address _address) public onlyOwner returns (bool success) {
        isDistributor[_address] = true;
        distributorCount++;
        return true;
    }

    /**
     * remove allowance to use cashNode
     * @param _address The address to remowe allowance
    */
    function blockDistributor(address _address) public onlyOwner returns (bool success) {
        isDistributor[_address] = false;
        return true;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() public payable returns (uint amount) {
        amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);
        emit Transfer(msg.sender, this, amount);
        return revenue;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}
