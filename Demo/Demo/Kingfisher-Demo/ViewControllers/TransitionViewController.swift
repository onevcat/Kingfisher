//
//  TransitionViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/18.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Kingfisher

class TransitionViewController: UIViewController {
    
    enum PickerComponent: Int, CaseIterable {
        case transitionType
        case duration
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var transitionPickerView: UIPickerView!
    
    let durations: [TimeInterval] = [0.5, 1, 2, 4, 10]
    let transitions: [String] = ["none", "fade", "flip - left", "flip - right", "flip - top", "flip - bottom"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transition"
        setupOperationNavigationBar()
        imageView.kf.indicatorType = .activity
    }
    
    func makeTransition(type: String, duration: TimeInterval) -> ImageTransition {
        switch type {
        case "none": return .none
        case "fade": return .fade(duration)
        case "flip - left": return .flipFromLeft(duration)
        case "flip - right": return .flipFromRight(duration)
        case "flip - top": return .flipFromTop(duration)
        case "flip - bottom": return .flipFromBottom(duration)
        default: return .none
        }
    }
    
    func reloadImageView() {
    
        let typeIndex = transitionPickerView.selectedRow(inComponent: PickerComponent.transitionType.rawValue)
        let transitionType = transitions[typeIndex]
        
        let durationIndex = transitionPickerView.selectedRow(inComponent: PickerComponent.duration.rawValue)
        let duration = durations[durationIndex]
        
        let t = makeTransition(type: transitionType, duration: duration)
        let url = ImageLoader.sampleImageURLs[0]
        KF.url(url)
            .forceTransition()
            .transition(t)
            .set(to: imageView)
    }
}

extension TransitionViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch PickerComponent(rawValue: component)!  {
        case .transitionType: return transitions[row]
        case .duration: return String(durations[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        reloadImageView()
    }
}

extension TransitionViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return PickerComponent.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch PickerComponent(rawValue: component)!  {
        case .transitionType: return transitions.count
        case .duration: return durations.count
        }
    }
}
