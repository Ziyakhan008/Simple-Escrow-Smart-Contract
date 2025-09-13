module MyModule::SimpleEscrow {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing an escrow agreement
    struct Escrow has store, key {
        buyer: address,           // Address of the buyer
        seller: address,          // Address of the seller
        amount: u64,              // Escrowed amount
        is_released: bool,        // Whether funds have been released
    }

    /// Function to create a new escrow agreement
    /// The buyer deposits funds to be held in escrow
    public fun create_escrow(
        buyer: &signer, 
        seller: address, 
        amount: u64
    ) {
        let buyer_addr = signer::address_of(buyer);
        
        // Create the escrow struct
        let escrow = Escrow {
            buyer: buyer_addr,
            seller,
            amount,
            is_released: false,
        };
        
        // Withdraw funds from buyer and hold them in the contract
        let payment = coin::withdraw<AptosCoin>(buyer, amount);
        coin::deposit<AptosCoin>(buyer_addr, payment);
        
        // Store the escrow agreement
        move_to(buyer, escrow);
    }

    /// Function to release escrowed funds to the seller
    /// Only the buyer can release the funds
    public fun release_funds(buyer: &signer, seller: address) acquires Escrow {
        let buyer_addr = signer::address_of(buyer);
        let escrow = borrow_global_mut<Escrow>(buyer_addr);
        
        // Verify the seller address matches
        assert!(escrow.seller == seller, 1);
        // Ensure funds haven't been released already
        assert!(!escrow.is_released, 2);
        
        // Transfer funds from buyer's account to seller
        let payment = coin::withdraw<AptosCoin>(buyer, escrow.amount);
        coin::deposit<AptosCoin>(seller, payment);
        
        // Mark as released
        escrow.is_released = true;
    }
}