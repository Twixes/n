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
  var userProvidedPartialNumber = false
  var userProvidedCurrentNumber = false
  var currentNumber = 0.0
  var partialNumber = 0.0 // addend, subtrahend, multiplier, divisor
  var partialMode = false
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
      if partialMode {
        display!.text = String(format: "%g", partialNumber) + suffix
      } else {
        display!.text = String(format: "%g", currentNumber) + suffix
      }
    }
  }
  
  func partialSwitch(_ on: Bool, sender: UIButton?) {
    partialNumber = 0.0
    userProvidedPartialNumber = false
    decimalPointMode = false
    decimalPointPlace = 0
    for button in operationButtons! {
      button.setTitleColor(black, for: .normal)
    }
    if on {
      partialMode = true
      operationMode = sender!.accessibilityLabel!
      sender!.setTitleColor(brandViolet, for: .normal)
    } else {
      partialMode = false
    }
  }
  
  func performOperation() {
    switch operationMode {
    case "add":
      currentNumber += partialNumber
    case "subtract":
      currentNumber -= partialNumber
    case "multiply":
      currentNumber *= partialNumber
    case "divide":
      if partialNumber == 0.0 {
        throwCalculationError()
      } else {
        currentNumber /= partialNumber
      }
    default:
      break
    }
    operationMode = ""
    partialSwitch(false, sender: nil)
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
    if partialMode && partialNumber != 0.0 {
      userProvidedPartialNumber = false
      partialNumber = 0.0
    } else if partialMode {
      partialSwitch(false, sender: nil)
      partialNumber = 0.0
    } else {
      currentNumber = 0.0
      clearButton!.setTitle("AC", for: .normal)
    }
    updateDisplay()
  }
  
  @IBAction func changeSign() {
    if partialMode && partialNumber != 0.0 {
      partialNumber *= -1
    } else if !partialMode && currentNumber != 0.0 {
      currentNumber *= -1
    }
    updateDisplay()
  }
  
  @IBAction func squareRoot() {
    if partialMode && partialNumber < 0 {
      throwCalculationError()
    } else if partialMode {
      partialNumber = sqrt(partialNumber)
    } else if currentNumber < 0 {
      throwCalculationError()
    } else {
      currentNumber = sqrt(currentNumber)
    }
    updateDisplay()
  }
  
  @IBAction func changeOperationMode(_ sender: UIButton) {
    if !calculationErrorThrown && userProvidedPartialNumber {
      performOperation()
      updateDisplay()
      partialSwitch(true, sender: sender)
    } else if !calculationErrorThrown {
      partialSwitch(true, sender: sender)
    }
  }

  @IBAction func equalSignTouch(_ sender: UIButton) {
    performOperation()
    partialSwitch(false, sender: nil)
    userProvidedCurrentNumber = false
    updateDisplay()
  }
  
  @IBAction func addDecimalPoint(_ sender: UIButton) {
    decimalPointMode = true
    if partialMode {
      userProvidedPartialNumber = true
    } else {
      userProvidedCurrentNumber = true
    }
    clearButton!.setTitle("C", for: .normal)
    updateDisplay()
  }
  
  @IBAction func digitTouch(_ sender: UIButton) {
    let digit = Double(sender.currentTitle!)!
    if partialMode {
      if !userProvidedPartialNumber {
        partialNumber = 0.0
        userProvidedPartialNumber = true
      }
    } else {
      if !userProvidedCurrentNumber {
        currentNumber = 0.0
        userProvidedCurrentNumber = true
      }
    }
    if decimalPointMode {
      decimalPointPlace += 1
      if partialMode {
        partialNumber = partialNumber + digit * pow(10.0, -Double(decimalPointPlace))
      } else {
        currentNumber = currentNumber + digit * pow(10.0, -Double(decimalPointPlace))
      }
    } else {
      if partialMode {
        partialNumber = partialNumber * 10.0 + digit
      } else {
        currentNumber = currentNumber * 10.0 + digit
      }
    }
    if digit != 0.0 {
      clearButton!.setTitle("C", for: .normal)
    }
    updateDisplay()
  }
  
}

