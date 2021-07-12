pragma solidity ^0.4.17; 

contract CampaignFactory{ 
   address[] public deployedCampaigns; 
   
   function createCampaign(uint minimum) public { 
       address newCampaign = new Campaign(minimum, msg.sender);  //creates a new contract which gets deployed to blockchain 
       
       deployedCampaigns.push(newCampaign); 
   }   
   
   function getDeployedCampaigns() public view returns (address[]) { 
       return deployedCampaigns;
   } 
} 

contract Campaign {  
    
    struct Request { 
        string description; 
        uint value; 
        address recipient; 
        bool complete;
        uint approvalCount;  
        mapping(address => bool) approvals;
    }
    
    Request[] public requests; 
    address public manager;  
    uint public minimumContribution;  
    mapping(address => bool) public approvers; 
    uint public approversCount;
    
    modifier restricted() { 
       require(msg.sender == manager); 
       _;
    }
    
    function Campaign(uint minimum, address creator) public { 
        manager = creator; 
        minimumContribution = minimum;
    } 
    
    function contribute() public payable { 
        require(msg.value > minimumContribution); 
        
        approvers[msg.sender] = true; 
        
        approversCount++;
    }
    
    //this function will only be called by the manager 
    //so we locked the funcion using restricted function modifier
    function createRequest(string description, uint value, address recipient) 
    public restricted {  
                 
        Request memory newRequest = Request({ 
            description: description, 
            value: value, 
            recipient: recipient, 
            complete: false, 
            approvalCount: 0
        }); 
        
        requests.push(newRequest);    
    }   
    
    function approveRequest(uint index) public {  
        Request storage request = requests[index];
        
        require(approvers[msg.sender]);  //first see if this person is a donator 
        require(!request.approvals[msg.sender]); //if this person has already voted on contract
        
       request.approvals[msg.sender] = true;
       request.approvalCount++; 
    }
    
    //manager will try to finalize a particular Request
    function finalizeRequest(uint index) public restricted { 
        
        Request storage request = requests[index]; 
        require(request.approvalCount > (approversCount/2)); 
        require(!request.complete); //if request already been processed so exit 
        
        request.recipient.transfer(request.value); 
        
        request.complete = true;
    } 
   
    //gonna return various values as required on the showCampaign Page
    function getSummary() public view returns (uint, uint, uint, uint, address) { 
        return ( 
            minimumContribution, 
            this.balance, 
            requests.length, 
            approversCount, 
            manager
        );
    } 
     
    //returns total requests count
    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
} 