// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;
contract crowdfunding
{
    mapping(address=>uint) public contributors; //mapping kaunsa contributor kitna pay kiya hai, address se ether pe jarahi hai
    address public manager;
    uint public minimumcontributions;
    uint public deadline;
    uint public target;
    uint public raisedamount;
    uint public noofcontributors;


    struct Request{
        string description;//request karrahe hai kissliye
        address payable recipient; // kiskeliye maangrahe hai
        uint value;// kitna derahe hain
        bool completed;//voting complete hui hai ki nahi
        uint noofvoters;//kitna logh vote kien hain
        mapping(address=>bool) voters;//unn voters ke address ko cosist karegi
    }
    mapping(uint=>Request) public requests; //multiple request aaeih 1. environment, 2.charity
    uint public numrequests;// increase karne ke liye

    constructor(uint _target,uint _deadline)
    {
        target=_target;
        deadline=block.timestamp+_deadline; //unix ke term mein value deta hai timestamp ,yeh bataega kab bana hai contract + deadline
        minimumcontributions=100 wei;
        manager=msg.sender;
        
    }
    function sendeth() public payable{
        require(block.timestamp<deadline,"Deadline has passed");// checks whether the time of contract is not finished yet
        require(msg.value>=minimumcontributions,"Minimum contributions is not met");// checks whether minimum paisa se kam hain ki jyada
        if(contributors[msg.sender]==0) //pehle jo transfer karega uss time toh value of cotributors toh 0 hi rahega
        //agar koi 2 baar transfer karraha hai
        //50 wei ,50 wei karke agar dega toh usko bhi count karega
        {
            noofcontributors++;
        }
        contributors[msg.sender]+=msg.value; //msg.sender mein woh kitna value bheja hai chalagaya
        raisedamount+=msg.value;//raised amount mein add kardega woh kitna donate kiya

    }
    function getcontractbalance() public view returns(uint)
    {
        return address(this).balance;
    }
    function refund() public 
    {
        require(block.timestamp>deadline && raisedamount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0," You are not eligible for refund");
        address payable user=payable(msg.sender);//explicitly payable banaya hai
        user.transfer(contributors[msg.sender]);// contributors[msg.sender] mein ether hi stored hai
        contributors[msg.sender]=0;// uska account ka value ko 0 kardiya hai
    }
    //contributors neh saara kaam karliya
    // ab manager kaam karega
    modifier onlymanager()// only manager canmodify the data
    {
        require(msg.sender==manager,"Only manager can call this function"); // modifier end hoga _; se
        _;
    }
    function createrequest(string memory _description,address payable _receipient,uint _value) public onlymanager // khali manager hi call karsakte hain
    {
        
        Request storage newRequest=requests[numrequests];//request type ka new request variable banaya---->numrequest jo variable hai woh 0 hai-->requests[0] pe kaunse Request ka struct hai
        //numrequest ek pointer hai jo point karta hai
        //new request point karraha hai request[0] ko point aur woh main structure ko point karraha hai
        numrequests++;
        newRequest.description=_description;
        newRequest.recipient=_receipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noofvoters=0;
    } 
    function voterequest(uint _requestno)public{
        require(contributors[msg.sender]>0,"You are not a contributor");
        Request storage thisrequest=requests[_requestno];// this request point karraha wohi structure jo user bheja
        require(thisrequest.voters[msg.sender]==false,"You have already voted");//initial value of bool is false so agar false nahi hai so print
        thisrequest.voters[msg.sender]=true;
        thisrequest.noofvoters++;
    }
    function makepayment(uint _requestno)public onlymanager
    {
        require(raisedamount>=target);
        Request storage thisrequest1=requests[_requestno];
        require(thisrequest1.completed==false,"The request has been completed");
        require(thisrequest1.noofvoters>noofcontributors/2,"Majority not satisified");//50 percent se jyada logh vote karrahe hai ki nahi
        thisrequest1.recipient.transfer(thisrequest1.value);
        thisrequest1.completed=true;
    }
}