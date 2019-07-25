//
//  CoreXDemoBitcoinClient.swift
//  CoreXDemo
//
//  Created by Ed Gamble on 11/8/18.
//  Copyright © 2018 Breadwallet AG. All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//

import Foundation
import BRCrypto

class CoreDemoListener: SystemListener {
    
    static let eventQueue: DispatchQueue = DispatchQueue.global()
    
    private var managerListeners: [WalletManagerListener] = []
    private var walletListeners: [WalletListener] = []
    private var transferListeners: [TransferListener] = []

    private let currencyCodesNeeded: [String]

    public init (currencyCodesNeeded: [String]) {
        self.currencyCodesNeeded = currencyCodesNeeded
    }

    private let currencyCodeToModeMap: [String : WalletManagerMode] = [
        Currency.codeAsBTC : WalletManagerMode.api_only,
        Currency.codeAsBCH : WalletManagerMode.p2p_only,
        Currency.codeAsETH : WalletManagerMode.api_only
        ]
    
    func add(managerListener: WalletManagerListener) {
        CoreDemoListener.eventQueue.async {
            if !self.managerListeners.contains (where: { $0 === managerListener }) {
                self.managerListeners.append (managerListener)
            }
        }
    }
    
    func remove(managerListener: WalletManagerListener) {
        CoreDemoListener.eventQueue.async {
            if let i = self.managerListeners.firstIndex (where: { $0 === managerListener }) {
                self.managerListeners.remove (at: i)
            }
        }
    }
    
    func add(walletListener: WalletListener) {
        CoreDemoListener.eventQueue.async {
            if !self.walletListeners.contains (where: { $0 === walletListener }) {
                self.walletListeners.append (walletListener)
            }
        }
    }
    
    func remove(walletListener: WalletListener) {
        CoreDemoListener.eventQueue.async {
            if let i = self.walletListeners.firstIndex (where: { $0 === walletListener }) {
                self.walletListeners.remove (at: i)
            }
        }
    }
    
    func add(transferListener: TransferListener) {
        CoreDemoListener.eventQueue.async {
            if !self.transferListeners.contains (where: { $0 === transferListener }) {
                self.transferListeners.append (transferListener)
            }
        }
    }

    func remove(transferListener: TransferListener) {
        CoreDemoListener.eventQueue.async {
            if let i = self.transferListeners.firstIndex (where: { $0 === transferListener }) {
                self.transferListeners.remove (at: i)
            }
        }
    }
    
    func handleSystemEvent(system: System, event: SystemEvent) {
        print ("APP: System: \(event)")
        switch event {
        case .created:
            break

        case .networkAdded(let network):
            var needMainnet = true

            #if TESTNET
            needMainnet = false
            #endif

            // A network was created; create the corresponding wallet manager.  Note: an actual
            // App might not be interested in having a wallet manager for every network -
            // specifically, test networks are announced and having a wallet manager for a
            // testnet won't happen in a deployed App.

            if needMainnet == network.isMainnet &&
                currencyCodesNeeded.contains (where: { nil != network.currencyBy (code: $0) }) {
                let mode = system.supportsMode (network: network, WalletManagerMode.api_only)
                    ? WalletManagerMode.api_only
                    : system.defaultMode(network: network)
                let scheme = system.defaultAddressScheme(network: network)

                let _ = system.createWalletManager (network: network,
                                                    mode: mode,
                                                    addressScheme: scheme)
            }
        case .managerAdded (let manager):
            //TODO: Don't connect here. connect on touch...
            manager.connect()

        }
    }

    func handleManagerEvent(system: System, manager: WalletManager, event: WalletManagerEvent) {
        CoreDemoListener.eventQueue.async {
            print ("APP: Manager (\(manager.name)): \(event)")
            self.managerListeners.forEach {
                $0.handleManagerEvent(system: system,
                                      manager: manager,
                                      event: event)
            }
        }
    }

    func handleWalletEvent(system: System, manager: WalletManager, wallet: Wallet, event: WalletEvent) {
        CoreDemoListener.eventQueue.async {
            print ("APP: Wallet (\(manager.name):\(wallet.name)): \(event)")
            self.walletListeners.forEach {
                $0.handleWalletEvent (system: system,
                                      manager: manager,
                                      wallet: wallet,
                                      event: event)
            }
        }
    }

    func handleTransferEvent(system: System, manager: WalletManager, wallet: Wallet, transfer: Transfer, event: TransferEvent) {
        CoreDemoListener.eventQueue.async {
            print ("APP: Transfer (\(manager.name):\(wallet.name)): \(event)")
            self.transferListeners.forEach {
                $0.handleTransferEvent (system: system,
                                        manager: manager,
                                        wallet: wallet,
                                        transfer: transfer,
                                        event: event)
            }
        }
    }

    func handleNetworkEvent(system: System, network: Network, event: NetworkEvent) {
        print ("APP: Network: \(event)")
    }
}

