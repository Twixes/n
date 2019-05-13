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
  
  let brandViolet = UIColor(0xA000FF)
  let brandGradient = [UIColor(0x8000FF).cgColor, UIColor(0xBF00FF).cgColor]
  let black = UIColor(0x000000)

  var wasCalculationErrorThrown = false
  var isNumberUserProvided = false // is number at current working level user-provided
  var inputModeOn = true

  var operationModes: [String?] = [nil, nil, nil]
  // at 0 is padding (always nil)
  // at 1 is "add", "subtract", "multiply" or "divide" - default lane
  // at 2 is "multiply" or "divide" - priority lane
  var workingNumbers = [0.0, 0.0, 0.0]
  // at 0 is final result
  // at 1 is addend, subtrahend, multiplier or divisor - default lane
  // at 2 is multiplier or divisor - priority lane
  var currentWorkingLevel = 0
  // 0 when there's no explicit operation mode - inferred lastInputOperationMode and lastInputNumber
  // 1 when merging workingNumbers[0] and workingNumbers[1] with operationModes[1] - default lane
  // 2 when merging workingNumbers[1] and workingNumbers[2] with operationModes[2] - priority lane
  var lastInputOperationMode: String? = nil
  var lastInputNumber = 0.0

  var decimalPointInputPlace: Int? = nil
  var decimalPointInputZero: Bool? = nil
  
  @IBOutlet var displayBackground: UIView?
  @IBOutlet var display: UILabel?
  @IBOutlet var clearButton: UIButton?
  @IBOutlet var zeroDigitButton: UIButton?
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
    zeroDigitButton!.titleEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: CGFloat(clearButton!.frame.size.width))
  }
  
  // functions

  func printDiagnostics() {
    print("# DIAGNOSTICS")
    print("wasCalculationErrorThrown = \(wasCalculationErrorThrown)")
    print("isNumberUserProvided = \(isNumberUserProvided)")
    print("inputModeOn = \(inputModeOn)")
    print("lastInputOperationMode = \(lastInputOperationMode as Optional)")
    print("lastInputNumber = \(lastInputNumber)")
    print("currentWorkingLevel = \(currentWorkingLevel)")
    print("operationModes = \(operationModes)")
    print("workingNumbers = \(workingNumbers)")
    print("decimalPointInputPlace = \(decimalPointInputPlace as Optional)")
    print("decimalPointInputZero = \(decimalPointInputZero as Optional)")
  }

  func updateDisplay(showLevelBelow: Bool = false) {
    var suffix = ""
    if decimalPointInputZero != nil && decimalPointInputZero! {
      suffix = "." + String(repeating: "0", count: decimalPointInputPlace!)
    }
    let levelToDisplay = !isNumberUserProvided && currentWorkingLevel > 0 ? currentWorkingLevel - 1 : currentWorkingLevel
    display!.text = String(format: "%g", workingNumbers[levelToDisplay]) + suffix
    printDiagnostics()
  }

  func updateOperationButtons() {
    // reset color of all operation buttons
    for button in operationButtons! {
      button.setTitleColor(black, for: .normal)
    }
    // set color of currently applicable operation button
    if let currentOperationMode = operationModes[currentWorkingLevel] {
      for button in operationButtons! {
        if button.accessibilityLabel! == currentOperationMode {
          button.setTitleColor(brandViolet, for: .normal)
          break
        }
      }
    }
  }

  func resetInput() {
    isNumberUserProvided = false
    decimalPointInputPlace = nil
    decimalPointInputZero = nil
  }
  
  func performOperation(withLastInput: Bool = false) {
    if withLastInput {
      if let lastInputOperationModeUnwrapped = lastInputOperationMode {
        switch lastInputOperationModeUnwrapped {
        case "add":
          workingNumbers[currentWorkingLevel] += lastInputNumber
        case "subtract":
          workingNumbers[currentWorkingLevel] -= lastInputNumber
        case "multiply":
          workingNumbers[currentWorkingLevel] *= lastInputNumber
        case "divide":
          if lastInputNumber == 0.0 {
            throwCalculationError()
          } else {
            workingNumbers[currentWorkingLevel] /= lastInputNumber
          }
        default:
          break
        }
      }
    } else if let currentOperationMode = operationModes[currentWorkingLevel] {
      switch currentOperationMode {
      case "add":
        workingNumbers[currentWorkingLevel-1] += workingNumbers[currentWorkingLevel]
      case "subtract":
        workingNumbers[currentWorkingLevel-1] -= workingNumbers[currentWorkingLevel]
      case "multiply":
        workingNumbers[currentWorkingLevel-1] *= workingNumbers[currentWorkingLevel]
      case "divide":
        if workingNumbers[currentWorkingLevel] == 0.0 {
          throwCalculationError()
        } else {
          workingNumbers[currentWorkingLevel-1] /= workingNumbers[currentWorkingLevel]
        }
      default:
        break
      }
      workingNumbers[currentWorkingLevel] = 0.0
    }

    inputModeOn = false

  }

  func levelDown() {
    operationModes[currentWorkingLevel] = nil
    workingNumbers[currentWorkingLevel] = 0.0
    if currentWorkingLevel > 0 {
      currentWorkingLevel -= 1
    }
  }

  func levelsReset() {
    wasCalculationErrorThrown = false
    inputModeOn = true
    currentWorkingLevel = 0
    operationModes = [nil, nil, nil]
    workingNumbers = [0.0, 0.0, 0.0]
    lastInputOperationMode = nil
    lastInputNumber = 0.0
  }

  func throwCalculationError() {
    wasCalculationErrorThrown = true
    display!.text = "error"
    levelsReset()
  }

  // actions
  
  @IBAction func clearNumber(_ sender: UIButton) {
    if isNumberUserProvided {
      workingNumbers[currentWorkingLevel] = 0.0
    } else {
      levelDown()
    }
    if currentWorkingLevel == 0 && workingNumbers == [0.0, 0.0, 0.0] {
      clearButton!.setTitle("AC", for: .normal)
    }
    resetInput()
    updateOperationButtons()
    updateDisplay()
  }
  
  @IBAction func changeSign() {
    guard !wasCalculationErrorThrown else { return }
    workingNumbers[currentWorkingLevel] *= -1
    if inputModeOn {
      lastInputNumber *= -1
    }
    isNumberUserProvided = true
    clearButton!.setTitle("C", for: .normal)
    updateDisplay()
  }
  
  @IBAction func squareRoot() {
    guard !wasCalculationErrorThrown else { return }
    guard workingNumbers[currentWorkingLevel] >= 0 else {
      throwCalculationError()
      return
    }
    workingNumbers[currentWorkingLevel] = sqrt(workingNumbers[currentWorkingLevel])
    updateDisplay()
  }
  
  @IBAction func changeOperationMode(_ sender: UIButton) {
    guard !wasCalculationErrorThrown else { return }

    var showLevelBelow = false

    if currentWorkingLevel == 2 {
      performOperation()
      if sender.accessibilityLabel! == "add" || sender.accessibilityLabel! == "subtract" {
        levelDown()
        performOperation()
        showLevelBelow = true
      }
      showLevelBelow = true
    } else if currentWorkingLevel == 1 {
      if (operationModes[1]! == "add" || operationModes[1]! == "subtract") && (sender.accessibilityLabel! == "multiply" || sender.accessibilityLabel! == "divide") {
        currentWorkingLevel = 2
      } else {
        performOperation()
        showLevelBelow = true
      }
    } else {
      currentWorkingLevel = 1
    }

    inputModeOn = true
    resetInput()
    updateDisplay(showLevelBelow: showLevelBelow)
    operationModes[currentWorkingLevel] = sender.accessibilityLabel!
    lastInputOperationMode = sender.accessibilityLabel!
    updateOperationButtons()
  }

  @IBAction func equalSignTouch(_ sender: UIButton) {
    guard !wasCalculationErrorThrown else { return }
    if currentWorkingLevel == 2 {
      if isNumberUserProvided {
        performOperation()
        levelDown()
      } else {
        levelDown()
        performOperation(withLastInput: true)
      }
      performOperation()
      levelDown()
    } else if currentWorkingLevel == 1 {
      if isNumberUserProvided {
        performOperation()
        levelDown()
      } else {
        levelDown()
        performOperation(withLastInput: true)
      }
    } else {
      performOperation(withLastInput: true)
    }
    resetInput()
    updateOperationButtons()
    updateDisplay()
  }
  
  @IBAction func addDecimalPoint(_ sender: UIButton) {
    guard !wasCalculationErrorThrown && decimalPointInputPlace == nil else { return }
    if !inputModeOn { levelsReset() }
    decimalPointInputPlace = 0
    decimalPointInputZero = true
    isNumberUserProvided = true
    clearButton!.setTitle("C", for: .normal)
    updateDisplay()
  }
  
  @IBAction func digitTouch(_ sender: UIButton) {
    guard !wasCalculationErrorThrown else { return }
    if !inputModeOn { levelsReset() }

    let digit = Double(sender.currentTitle!)!
    if digit != 0.0 {
      isNumberUserProvided = true
      clearButton!.setTitle("C", for: .normal)
    }

    var signMultiplier = 1.0
    if workingNumbers[currentWorkingLevel].sign == .minus {
      signMultiplier = -1.0
    }

    if decimalPointInputPlace != nil {
      decimalPointInputPlace! += 1
      workingNumbers[currentWorkingLevel] = workingNumbers[currentWorkingLevel] + signMultiplier * digit * pow(10.0, -Double(decimalPointInputPlace!))
      if digit != 0.0 {
        decimalPointInputZero = false
      }
    } else {
      workingNumbers[currentWorkingLevel] = workingNumbers[currentWorkingLevel] * 10.0 + signMultiplier * digit
    }

    lastInputNumber = workingNumbers[currentWorkingLevel]

    updateDisplay()
  }
  
}

