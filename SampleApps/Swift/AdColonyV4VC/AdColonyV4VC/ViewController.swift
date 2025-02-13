//
//  ViewController.swift
//  AdColonyV4VC
//
//  Copyright (c) 2016 AdColony. All rights reserved.
//

import UIKit

struct Constants {
    
    static let adColonyAppID = "appbdee68ae27024084bb334a"
    static let adColonyZoneID = "vzf8e4e97704c4445c87504e"
    
    static let currencyBalance = "CurrencyBalance"
    static let currencyBalanceChange = "CurrencyBalanceChange"
    
}


class ViewController: UIViewController, AdColonyInterstitialDelegate {
    
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var ad: AdColonyInterstitial?

    //=============================================
    // MARK:- UIViewController Overrides
    //=============================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize AdColony on initial launch
        AdColony.configure(withAppID: Constants.adColonyAppID, options: nil) { [weak self] (zones) in
            //Set the zone's reward handler
            //This implementation is designed for client-side virtual currency without a server
            //It uses NSUserDefaults for persistent client-side storage of the currency balance
            //For applications with a server, contact the server to retrieve an updated currency balance
            let zone = zones.first
            zone?.setReward({ [weak self] (success, name, amount) in
                if (success) {
                    
                    //Get currency balance from persistent storage and update it
                    let storage = UserDefaults.standard
                    let wrappedBalance = storage.object(forKey: Constants.currencyBalance)
                    var balance: Int = 0
                    if let nonNilNumWrappedBalance = wrappedBalance as? NSNumber {
                        balance = Int(nonNilNumWrappedBalance.uintValue)
                    }
                    balance += Int(amount)
                        
                    //Persist the currency balance
                    let newBalance: NSNumber = NSNumber(integerLiteral: balance)
                    storage.set(newBalance, forKey: Constants.currencyBalance)
                    storage.synchronize()
                        
                    //Update the UI with the new balance
                    self?.updateCurrencyBalance()
                }
            })
            
            //If the application has been inactive for a while, our ad might have expired so let's add a check for a nil ad object
            NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                   object: nil,
                                                   queue: OperationQueue.main,
                                                   using: { notification in
                                                    //If our ad has expired, request a new interstitial
                                                    if (self?.ad == nil) {
                                                        self?.requestInterstitial()
                                                    }
            })
            
            //AdColony has finished configuring, so let's request an interstitial ad
            self?.requestInterstitial()
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.spinner.style = UIActivityIndicatorView.Style.whiteLarge
        } else {
            self.spinner.style = UIActivityIndicatorView.Style.white
        }
        
        self.updateCurrencyBalance()
        self.setLoadingState()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
   
    //=============================================
    // MARK:- AdColony
    //=============================================
    
    func requestInterstitial() {
        self.setLoadingState()
        
        //Request an interstitial ad from AdColony
        AdColony.requestInterstitial(inZone: Constants.adColonyZoneID, options: nil, andDelegate: self)
    }
    
    func adColonyInterstitialDidLoad(_ interstitial: AdColonyInterstitial) {
        //Store a reference to the returned interstitial object
        self.ad = interstitial
        
        //Show the user we are ready to play a video
        self.setReadyState()
    }
    
    func adColonyInterstitialDidFail(toLoad error: AdColonyAdRequestError) {
        if let reason = error.localizedFailureReason {
            print("SAMPLE_APP: Request failed in zone \(error.zoneId) with error: \(error.localizedDescription) and failure reason: \(reason)")
        } else if let recoverySuggestion = error.localizedRecoverySuggestion {
            print("SAMPLE_APP: Request failed in zone \(error.zoneId) with error: \(error.localizedDescription) and recovery suggestion: \(recoverySuggestion)")
        } else {
            print("SAMPLE_APP: Request failed in zone \(error.zoneId) with error: \(error.localizedDescription)")
        }
    }
    
    func adColonyInterstitialExpired(_ interstitial: AdColonyInterstitial) {
        self.ad = nil
        self.requestInterstitial()
    }
    
    func adColonyInterstitialDidClose(_ interstitial: AdColonyInterstitial) {
        self.ad = nil
        self.requestInterstitial()
    }
    
    @IBAction func triggerVideo(_ sender: AnyObject) {
        if let ad = self.ad, !ad.expired {
            ad.show(withPresenting: self)
        }
    }
    
    
    //=============================================
    // MARK:- UI
    //=============================================
    
    func setLoadingState() {
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        self.button.alpha = 0.0
        
        UIView.animate(withDuration: 1.0) {
            self.statusLabel.alpha = 1.0
        }
    }
    
    func setReadyState() {
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
        self.statusLabel.alpha = 0.0
        
        UIView.animate(withDuration: 1.0) {
            self.button.alpha = 1.0
        }
    }
    
    func updateCurrencyBalance() {
        //Get currency balance from persistent storage and display it
        let storage = UserDefaults.standard
        let wrappedBalance = storage.object(forKey: Constants.currencyBalance)
        var balance: Int = 0
        if let nonNilNumWrappedBalance = wrappedBalance as? NSNumber {
            balance = Int(nonNilNumWrappedBalance.uintValue)
        }
        
        self.currencyLabel.text = String(format: "%d", balance)
    }
    
}
