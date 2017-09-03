//
//  ViewController.swift
//  n
//
//  Copyright © 2017 Twixes. All rights reserved.
//

import UIKit
import CoreGraphics

// hex support for UIColor

extension UIColor {
  convenience init(_ hex: UInt) {
    self.init(
      red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(hex & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }
}

// view control

class ViewController: UIViewController {
  
  let brandViolet = UIColor.init(0xA000FF)
  let brandGradient = [UIColor.init(0x8000FF).cgColor, UIColor.init(0xBF00FF).cgColor]
  let black = UIColor.init(0x000000)
  var calculationErrorThrown = false
  var userProvidedPrimaryNumber = false
  var userProvidedSecondaryNumber = false
  var primaryNumber = 0.0
  var secondaryNumber = 0.0 // addend, subtrahend, multiplier, divisor
  var secondaryMode = false
  var operationMode = "" // add, subtract, multiply, divide
  var decimalPointMode = false
  var decimalPointPlace = 0
  
  @IBOutlet weak var displayBackground: UIView?
  @IBOutlet weak var display: UILabel?
  @IBOutlet weak var clearButton: UIButton?
  @IBOutlet weak var zeroDigitButton: UIButton?
  @IBOutlet var operationButtons: [UIButton]?
  
  // ran on load
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // stripe rendering
    let stripe = CAGradientLayer()
    stripe.colors = brandGradient
    stripe.frame = CGRect(x: 0, y: displayBackground!.frame.size.height - 6, width: view.frame.size.width, height: 6)
    stripe.startPoint = CGPoint(x: 0, y: 0)
    stripe.endPoint = CGPoint(x: 1, y: 0)
    view.layer.addSublayer(stripe)
    // title inset correction for the "0" button
    zeroDigitButton!.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, CGFloat(clearButton!.frame.size.width))
  }
  
  // functions
  
  func updateDisplay() {
    if !calculationErrorThrown {
      var suffix = ""
      if decimalPointMode && decimalPointPlace == 0 {
        suffix = "."
      }
      if secondaryMode {
        display!.text = String(format: "%g", secondaryNumber) + suffix
      } else {
        display!.text = String(format: "%g", primaryNumber) + suffix
      }
    }
  }
  
  func partialSwitch(_ on: Bool, sender: UIButton?) {
    secondaryNumber = 0.0
    userProvidedSecondaryNumber = false
    decimalPointMode = false
    decimalPointPlace = 0
    for button in operationButtons! {
      button.setTitleColor(black, for: .normal)
    }
    if on {
      secondaryMode = true
      operationMode = sender!.accessibilityLabel!
      sender!.setTitleColor(brandViolet, for: .normal)
    } else {
      secondaryMode = false
    }
  }
  
  func performOperation() {
    switch operationMode {
    case "add":
      primaryNumber += secondaryNumber
    case "subtract":
      primaryNumber -= secondaryNumber
    case "multiply":
      primaryNumber *= secondaryNumber
    case "divide":
      if secondaryNumber == 0.0 {
        throwCalculationError()
      } else {
        primaryNumber /= secondaryNumber
      }
    default:
      break
    }
  }
  
  func throwCalculationError() {
    calculationErrorThrown = true
    display!.text = "error"
  }
  
  // actions
  
  @IBAction func clearNumber(_ sender: UIButton) {
    calculationErrorThrown = false
    decimalPointMode = false
    decimalPointPlace = 0
    if secondaryMode && userProvidedSecondaryNumber {
      partialSwitch(false, sender: nil)
      secondaryNumber = 0.0
      operationMode = ""
    } else if secondaryMode {
      partialSwitch(false, sender: nil)
      userProvidedSecondaryNumber = false
      secondaryNumber = 0.0
    } else {
      primaryNumber = 0.0
      operationMode = ""
      clearButton!.setTitle("AC", for: .normal)
    }
    updateDisplay()
  }
  
  @IBAction func changeSign() {
    if secondaryMode && secondaryNumber != 0.0 {
      secondaryNumber *= -1
    } else if !secondaryMode && primaryNumber != 0.0 {
      primaryNumber *= -1
    }
    updateDisplay()
  }
  
  @IBAction func squareRoot() {
    if secondaryMode && secondaryNumber < 0 {
      throwCalculationError()
    } else if secondaryMode {
      secondaryNumber = sqrt(secondaryNumber)
    } else if primaryNumber < 0 {
      throwCalculationError()
    } else {
      primaryNumber = sqrt(primaryNumber)
    }
    updateDisplay()
  }
  
  @IBAction func changeOperationMode(_ sender: UIButton) {
    if !calculationErrorThrown && userProvidedSecondaryNumber {
      performOperation()
      updateDisplay()
      partialSwitch(true, sender: sender)
    } else if !calculationErrorThrown {
      partialSwitch(true, sender: sender)
    }
  }

  @IBAction func equalSignTouch(_ sender: UIButton) {
    performOperation()
    decimalPointMode = false
    decimalPointPlace = 0
    secondaryMode = false
    userProvidedPrimaryNumber = false
    updateDisplay()
  }
  
  @IBAction func addDecimalPoint(_ sender: UIButton) {
    decimalPointMode = true
    if secondaryMode {
      userProvidedSecondaryNumber = true
    } else {
      userProvidedPrimaryNumber = true
    }
    clearButton!.setTitle("C", for: .normal)
    updateDisplay()
  }
  
  @IBAction func digitTouch(_ sender: UIButton) {
    let digit = Double(sender.currentTitle!)!
    if secondaryMode {
      if !userProvidedSecondaryNumber {
        secondaryNumber = 0.0
        userProvidedSecondaryNumber = true
      }
    } else {
      if !userProvidedPrimaryNumber {
        primaryNumber = 0.0
        userProvidedPrimaryNumber = true
      }
    }
    if decimalPointMode {
      decimalPointPlace += 1
      if secondaryMode {
        secondaryNumber = secondaryNumber + digit * pow(10.0, -Double(decimalPointPlace))
      } else {
        primaryNumber = primaryNumber + digit * pow(10.0, -Double(decimalPointPlace))
      }
    } else {
      if secondaryMode {
        secondaryNumber = secondaryNumber * 10.0 + digit
      } else {
        primaryNumber = primaryNumber * 10.0 + digit
      }
    }
    if digit != 0.0 {
      clearButton!.setTitle("C", for: .normal)
    }
    updateDisplay()
  }
  
}

