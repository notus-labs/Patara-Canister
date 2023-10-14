import HashMap "mo:base/HashMap";
import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Int "mo:base/Int";

shared(messager) actor class PasswordManager() {
  type CycleWalletActor = actor {
        wallet_receive() : async ();
  };
  
  let vault = HashMap.HashMap<Blob, [Nat8]>(0, Blob.equal, Blob.hash);
  let owner = messager.caller;
  stable var nextPaymentDate: Int = Time.now() + 30 * 24 * 60 * 60 * 1000; // Add 30 days
  let minPaymentAmount: Int = 10_000_000; // 10M cycles
  let remoteWallet : CycleWalletActor = actor(Principal.toText(messager.caller)); // Change this to the patara treasury

  public shared(msg) func pay(
    amount: Nat
  ): async { refunded: Nat} {
    assert(amount >= minPaymentAmount);
    nextPaymentDate := Time.now() + 30 * 24 * 60 * 60 * 1000; // Add 30 days

    // Send the money to the patara treasury
    Cycles.add(amount);
    let result = await remoteWallet.wallet_receive();

    { refunded = Cycles.refunded(); }
  };

  public shared(msg) func add_or_replace(
    key: Blob,
    value: [Nat8],
    amount: Nat
  ): async { refunded: Nat} {
    assert(nextPaymentDate > Time.now());

    Cycles.add(amount);
    let result = await remoteWallet.wallet_receive();
    vault.put(key, value);

    { refunded = Cycles.refunded(); }
  };

  public query func keys(): async [Blob] {
    let result = Iter.toArray(vault.keys());
    result
  };

  public query func get(
    key: Blob
  ): async ?[Nat8] {
    let result = vault.get(key);
    result
  };
};
