//
//  TextInputsManager.swift
//  SKUtilsSwift
//
//  Created by Sergey Kostyan on 19.07.16.
//  Copyright © 2016 Sergey Kostyan. All rights reserved.
//

import UIKit

open class TextInputsManager: NSObject, KeyboardHiding, TextInputsClearing, TextFieldsManagerReloading, FirstResponding {
    
    @IBInspectable var hideOnTap: Bool = true
    @IBInspectable var nextBecomesFirstResponder: Bool = true
    @IBInspectable var handleReturnKeyType: Bool = true
    @IBInspectable var additionalSpaceAboveKeyboard: CGFloat = 20.0
    
    @IBOutlet private weak var containerView: UIView! {
        didSet {
            configureManager()
        }
    }
    private var viewOriginalFrame = CGRect.zero
    private var textInputs = [UIView]()
    
    var returnKeyProvider: ((Int, Bool) -> UIReturnKeyType)? = { (_, isLast) -> UIReturnKeyType in
        guard isLast else { return .next }
        return .done
    }
    
    // MARK: - Life -
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        textInputs.forEach { (textInput) in
            guard let textView = textInput as? UITextView else { return }
            NotificationCenter.default.removeObserver(self, name: .UITextViewTextDidEndEditing, object: textView)
        }
    }
    
    // MARK: - Private -
    
    private func configureManager() {
        subscribeForKeyboardNotifications()
        collectTextInputs()
        guard hideOnTap else { return }
        addTapGestureRecognizer()
    }
    
    private func subscribeForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    /* Collects all subviews with type UITextField and UITextView */
    
    private func collectTextInputs() {
        viewOriginalFrame = containerView.frame
        textInputs += collectTextFields()
        textInputs += collectTextViews()
        sortInputsByOrigin()
        guard handleReturnKeyType else { return }
        assignReturnKeys()
    }
    
    private func collectTextFields() -> [UIView] {
        let textFields: [UIView] = containerView.subviewsOf(type: UITextField.self).compactMap { (textField) -> UIView? in
            textField.addTarget(self, action: #selector(didFinishEdititng), for: .editingDidEndOnExit)
            return textField
        }
        return textFields
    }
    
    private func collectTextViews() -> [UIView] {
        let textViews: [UIView] = containerView.subviewsOf(type: UITextView.self).compactMap { (textView) -> UIView? in
            NotificationCenter.default.addObserver(self, selector: #selector(textViewDidFinishEdititng), name: .UITextViewTextDidEndEditing,
                                                   object: textView)
            return textView
        }
        return textViews
    }
    
    private func sortInputsByOrigin() {
        guard let window = UIApplication.shared.keyWindow else { return }
        textInputs.sort { (currentObject, nextObject) -> Bool in
            let currentObjectRect = currentObject.convert(currentObject.frame, to: window)
            let nextObjectRect = nextObject.convert(nextObject.frame, to: window)
            guard currentObjectRect.origin.y != nextObjectRect.origin.y else {
                return currentObjectRect.origin.x < nextObjectRect.origin.x
            }
            return currentObjectRect.origin.y < nextObjectRect.origin.y
        }
    }
    
    private func addTapGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        containerView.addGestureRecognizer(tap)
    }
    
    private func activateField(at index: Int) {
        guard textInputs.indices.contains(index) else {
            hideKeyboard()
            return
        }
        let nextInputView = textInputs[index]
        guard nextInputView.canBecomeFirstResponder else {
            activateField(at: index + 1)
            return
        }
        nextInputView.becomeFirstResponder()
    }
    
    private func assignReturnKeys() {
        textInputs.enumerated().forEach { [weak self] (index, inputView) in
            self?.assignReturnKey(for: inputView, at: index)
        }
    }
    
    private func assignReturnKey(for inputView: UIView, at index: Int) {
        guard let textField = inputView as? UITextField, let returnKeyProvider = returnKeyProvider else { return }
        let isLast = textInputs.indices.last == index
        textField.returnKeyType = returnKeyProvider(index, isLast)
    }
    
    private func animateKeyboardAction(withInfoFrom notification: Notification, actionHandler: @escaping ((CGRect) -> Void)) {
        guard let userInfo = notification.userInfo, let rect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: animationDurarion, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
            actionHandler(rect)
        }, completion: nil)
    }
    
    // MARK: - Private Notifications Selectors -
    
    @objc private func textViewDidFinishEdititng(_ notification: Notification) {
        guard let textView = notification.object as? UITextView, textView.isFirstResponder else { return }
        didFinishEdititng(textView)
    }
    
    @objc private func didFinishEdititng(_ textInput: UITextInput) {
        guard let index = textInputs.index(where: {$0 === textInput}), nextBecomesFirstResponder else {
            hideKeyboard()
            return }
        activateField(at: index + 1)
    }
    
    // MARK: - Keyboard notifications -
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        animateKeyboardAction(withInfoFrom: notification) { [weak self] (rect) in
            self?.keyboardWillShow(keyboardFrame: rect)
            self?.moveToActiveTextInput(keyboardFrame: rect)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        animateKeyboardAction(withInfoFrom: notification) { [weak self] (_) in
            self?.keyboardWillHide()
        }
    }
    
    // MARK: - Behaviour for containerView -
    
    private func moveToActiveTextInput(keyboardFrame rect: CGRect) {
        guard let activeInputView = firstResponder() else { return }
        var frame = containerView.convert(activeInputView.bounds, from: activeInputView)
        frame.origin.y += additionalSpaceAboveKeyboard
        guard let scroll = containerView as? UIScrollView else {
            let visibleContentHeight = viewOriginalFrame.height - rect.height
            guard frame.maxY > visibleContentHeight else { return }
            let delta = frame.maxY - visibleContentHeight
            containerView.frame.origin.y -= delta
            return
        }
        scroll.scrollRectToVisible(frame, animated: false)
    }
    
    private func keyboardWillShow(keyboardFrame rect: CGRect) {
        guard let scroll = containerView as? UIScrollView else { return }
        let distance = UIScreen.main.bounds.maxY - containerView.frame.maxY
        let bottomInset = rect.size.height - distance + additionalSpaceAboveKeyboard
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
    }
    
    private func keyboardWillHide() {
        guard let scroll = containerView as? UIScrollView else {
            containerView.frame = viewOriginalFrame
            return
        }
        scroll.contentInset = UIEdgeInsets.zero
    }
    
    // MARK: - KeyboardHiding -
    
    @objc public func hideKeyboard() {
        textInputs.forEach { textInput in
            guard textInput.isFirstResponder else { return }
            _ = textInput.resignFirstResponder()
        }
    }
    
    // MARK: - TextInputsClearing -
    
    
    public func clearTextInputs() {
        for textInput in textInputs {
            if let textField = textInput as? UITextField {
                textField.text = nil
                textField.attributedText = nil
            }
            if let textView = textInput as? UITextView {
                textView.text = String()
                textView.attributedText = NSAttributedString(string: String())
            }
        }
    }
    
    // MARK: - TextFieldsManagerReloading -
    
    public func reloadTextFieldsManager() {
        textInputs.removeAll()
        collectTextInputs()
    }
    
    // MARK: - FirstResponding -
    
    public func firstResponder() -> UIView? {
        let textInput = textInputs.first(where: { (textInput) -> Bool in
            return textInput.isFirstResponder
        })
        return textInput
    }
}

// MARK: - UIGestureRecognizerDelegate -

extension TextInputsManager: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tables: [UIView] = containerView.subviewsOf(type: UITableView.self)
        let collections: [UIView] = containerView.subviewsOf(type: UICollectionView.self)
        var subviews = [UIView]()
        subviews += tables
        subviews += collections
        for subview in subviews {
            let point = gestureRecognizer.location(in: subview)
            if subview.point(inside: point, with: nil) {
                return false
            }
        }
        return true
    }
    
}

// MARK: - UIView -

private extension UIView {
    
    func subviewsOf<T>(type: T.Type) -> [T] {
        var searchedSubviews = [T]()
        for subview in subviews {
            if let view = subview as? T {
                searchedSubviews.append(view)
            } else {
                searchedSubviews += subview.subviewsOf(type: T.self)
            }
        }
        return searchedSubviews
    }
    
}
