# 📚 Resource Library Access Controller

A comprehensive Clarity smart contract for managing digital library resources, memberships, and access control on the Stacks blockchain.

## 🌟 Features

- **📖 Resource Management**: Add and track library resources (books, digital media, etc.)
- **👥 Member Registration**: Register and manage library members with expiration dates
- **🔄 Checkout System**: Complete checkout/return workflow with due dates
- **🔄 Renewal System**: Allow members to renew resources (up to 2 renewals)
- **💰 Late Fee Management**: Automatic calculation and tracking of overdue fees
- **🔐 Access Control**: Owner-only administrative functions
- **📊 Statistics**: Contract-wide statistics and member activity tracking
- **⏰ Membership Expiry**: Time-based membership validation

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `clarinet check` to verify contract compilation

## 📋 Usage

### Admin Functions (Owner Only)

#### Adding Resources
```clarity
(contract-call? .Resource-Library-Access-Controller add-resource 
  "The Great Gatsby" 
  "book" 
  "F. Scott Fitzgerald" 
  "978-0-7432-7356-5" 
  u3)
```

#### Registering Members
```clarity
(contract-call? .Resource-Library-Access-Controller register-member 
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
  "John Doe" 
  "john@example.com" 
  "premium" 
  u365)
```

#### Managing Members
```clarity
;; Suspend a member
(contract-call? .Resource-Library-Access-Controller suspend-member u1)

;; Reactivate a member
(contract-call? .Resource-Library-Access-Controller reactivate-member u1)

;; Update late fee (per day)
(contract-call? .Resource-Library-Access-Controller update-late-fee u150)
```

### Member Functions

#### Checkout Resources
```clarity
(contract-call? .Resource-Library-Access-Controller checkout-resource u1)
```

#### Return Resources
```clarity
(contract-call? .Resource-Library-Access-Controller return-resource u1)
```

#### Renew Resources
```clarity
(contract-call? .Resource-Library-Access-Controller renew-resource u1)
```

### Read-Only Functions

#### Get Resource Information
```clarity
(contract-call? .Resource-Library-Access-Controller get-resource u1)
(contract-call? .Resource-Library-Access-Controller get-resource-availability u1)
```

#### Get Member Information
```clarity
(contract-call? .Resource-Library-Access-Controller get-member u1)
(contract-call? .Resource-Library-Access-Controller get-member-by-wallet 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### Get Checkout Information
```clarity
(contract-call? .Resource-Library-Access-Controller get-checkout u1)
(contract-call? .Resource-Library-Access-Controller is-resource-overdue u1)
(contract-call? .Resource-Library-Access-Controller calculate-late-fee u1)
```

#### Get Statistics
```clarity
(contract-call? .Resource-Library-Access-Controller get-contract-stats)
```

## 🏗️ Contract Structure

### Constants
- **Error Codes**: Comprehensive error handling (100-109)
- **Contract Owner**: Set at deployment time

### Data Variables
- `next-resource-id`: Auto-incrementing resource identifier
- `next-member-id`: Auto-incrementing member identifier  
- `late-fee-per-day`: Configurable daily late fee (default: 100 microSTX)
- `max-checkout-days`: Maximum checkout period (default: 14 days)
- `max-renewals`: Maximum number of renewals (default: 2)

### Data Maps
- **resources**: Store resource metadata and availability
- **members**: Store member information and statistics
- **checkouts**: Track all checkout transactions
- **member-wallets**: Map wallet addresses to member IDs
- **resource-queue**: Future implementation for waitlists

## 🔧 Configuration

Default settings can be modified by the contract owner:

- **Late Fee**: 100 microSTX per day
- **Checkout Period**: 14 days
- **Maximum Renewals**: 2 per checkout

## 🛡️ Security Features

- **Owner-only functions**: Administrative tasks restricted to contract deployer
- **Member authentication**: Checkout/return limited to registered members
- **Membership validation**: Automatic expiry checking
- **Resource availability**: Prevents over-checkout of limited resources
- **Input validation**: Comprehensive parameter checking

## 📊 Statistics Tracking

The contract tracks:
- Total resources in library
- Total registered members  
- Total checkout transactions
- Member checkout history
- Overdue incidents per member
- Late fees accumulated

## 🚨 Error Codes

- `u100`: Owner-only function called by non-owner
- `u101`: Resource/member/checkout not found
- `u102`: Resource/member already exists
- `u103`: Unauthorized access attempt
- `u104`: Resource unavailable for checkout
- `u105`: Invalid parameters provided
- `u106`: Access denied (suspended member)
- `u107`: Membership expired
- `u108`: Resource already checked out
- `u109`: Cannot renew overdue resource

## 🧪 Testing

Run the test suite:
```bash
npm install
npm test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

Built with ❤️ using Clarity smart contract language for the Stacks blockchain.
