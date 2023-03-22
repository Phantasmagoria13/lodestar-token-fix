pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenFix is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public oldToken;
    IERC20 public newToken;
    address public admin;

    event tokenClaimed(address claimer, uint256 claimAmount);
    event adminUpdated(address oldAdmin, address newAdmin);

    constructor(IERC20 _oldToken, IERC20 _newToken, address _admin) {
        oldToken = _oldToken;
        newToken = _newToken;
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!Admin");
        _;
    }

    function swap(uint256 swapAmount) public nonReentrant {
        swapInternal(swapAmount);
    }

    //@notice this function is to swap old tokens for new tokens at a 1:1 rate
    function swapInternal(uint256 swapAmount) internal {
        uint256 userBalance = IERC20(oldToken).balanceOf(msg.sender);

        if (swapAmount > userBalance) {
            revert("Swap amount exceeds balance");
        }

        unchecked{
            userBalance = userBalance - swapAmount;
        }

        oldToken.safeTransferFrom(msg.sender, address(this), swapAmount);

        newToken.safeTransferFrom(address(this), msg.sender, swapAmount);

        emit tokenClaimed(msg.sender, swapAmount);
    }

    //**ADMIN FUNCTIONS**

    function _setAdmin(address _newAdmin) public onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit adminUpdated(oldAdmin, _newAdmin);
    }

    function _adminTransferAll() public onlyAdmin {
        uint256 amount = newToken.balanceOf(address(this));
        newToken.safeTransferFrom(address(this), msg.sender, amount);
    }

    function _adminTransfer(uint256 amount) public onlyAdmin {
        newToken.safeTransferFrom(address(this), msg.sender, amount);
    }
}
