//
//  TextInputsManager.swift
//  SKUtilsSwift
//
//  Created by Sergey Kostyan on 19.07.16.
//  Copyright © 2016 Sergey Kostyan. All rights reserved.
//

import UIKit

public typealias ReturnKeyProviderHandler = ((Int, Bool) -> UIReturnKeyType)

open class TextInputsManager: NSObject, KeyboardHiding, TextInputsClearing, TextInputsManagerReloading, FirstResponding {
    
    @IBInspectable private var hideOnTap: Bool = true
    @IBInspectable private var nextBecomesFirstResponder: Bool = true
    @IBInspectable private var handleReturnKeyType: Bool = true
    @IBInspectable private var additionalSpaceAboveKeyboard: CGFloat = 20.0

    @IBOutlet private weak var containerView: UIView!
    
    private var keyboardRect = CGRect.zero
    private var textInputs = [UIView]()
    
    private var returnKeyProvider: ReturnKeyProviderHandler = { (_, isLast) -> UIReturnKeyType in
        guard isLast else { return .next }
        return .done
    }
    
    // MARK: - Life -
    
    deinit {
        unsubscribeFromAllNotifications()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        configureManager()
        addTapGestureRecognizer(to: containerView, needed: hideOnTap)
    }
    
    // MARK: - Private -
    
    private func configureManager() {
        subscribeForKeyboardNotifications()
        textInputs = collectTextInputs(in: containerView)
        textInputs.sortByOrigin(convertedTo: UIApplication.shared.keyWindow)
    }
    
    private func reset() {
        unsubscribeFromAllNotifications()
        textInputs.removeAll()
    }
    
    private func unsubscribeFromAllNotifications() {
        textInputs.compactMap({ $0 as? UITextView }).forEach { (textView) in
            unsubscribeForNotifications(for: textView)
        }
        unsubscribeForKeyboardNotifications()
    }
    
    private func subscribeForKeyboardNotifications() {
        unsubscribeForKeyboardNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    private func unsubscribeForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    private func subscribeForNotifications(for textView: UITextView) {
        unsubscribeForNotifications(for: textView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidFinishEdititng), name: .UITextViewTextDidEndEditing,
                                               object: textView)
    }
    
    private func unsubscribeForNotifications(for textView: UITextView) {
        NotificationCenter.default.removeObserver(self, name: .UITextViewTextDidEndEditing, object: textView)
    }
    
    /* Collects all subviews with type UITextField and UITextView */
    
    private func collectTextInputs(in container: UIView) -> [UIView] {
        return collectTextFields(in: container) + collectTextViews(in: container)
    }
    
    private func collectTextFields(in container: UIView) -> [UIView] {
        let textFields = container.subviewsOf(type: UITextField.self)
        textFields.forEach { (textField) in
            textField.addTarget(self, action: #selector(didFinishEdititng), for: .editingDidEndOnExit)
        }
        return textFields
    }
    
    private func collectTextViews(in container: UIView) -> [UIView] {
        let textViews = container.subviewsOf(type: UITextView.self)
        textViews.forEach { (textView) in
            subscribeForNotifications(for: textView)
        }
        return textViews
    }
    
    /* Adding Tap Gesture */
    
    private func addTapGestureRecognizer(to container: UIView, needed: Bool) {
        guard needed else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        container.addGestureRecognizer(tap)
    }
    
    private func activateField(at index: Int) {
        guard textInputs.indices.contains(index) else {
            hideKeyboard()
            return
        }
        let nextInputView = textInputs[index]
        guard nextInputView.canBecomeFirstResponder else {
            let nextIndex = index + 1
            activateField(at: nextIndex)
            return
        }
        nextInputView.becomeFirstResponder()
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.moveToActiveTextInput(keyboardFrame: strongSelf.keyboardRect)
        }
    }
    
    private func assignReturnKeys() {
        textInputs.enumerated().forEach { [weak self] (index, inputView) in
            self?.assignReturnKey(for: inputView, at: index)
        }
    }
    
    private func assignReturnKey(for inputView: UIView, at index: Int) {
        guard let textField = inputView as? UITextField else { return }
        let isLast = textInputs.indices.last == index
        textField.returnKeyType = returnKeyProvider(index, isLast)
    }
    
    private func animateKeyboardAction(withInfoFrom notification: Notification, actionHandler: @escaping ((CGRect) -> Void)) {
        guard let userInfo = notification.userInfo, let rect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt else { return }
        keyboardRect = rect
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
        let nextIndex = index + 1
        activateField(at: nextIndex)
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
            containerView.transform = .identity
            let visibleContentHeight = UIScreen.main.bounds.height - rect.height
            let yPositionRelativeToWindow = containerView.frame.minY + frame.maxY
            guard yPositionRelativeToWindow > visibleContentHeight else { return }
            let delta = yPositionRelativeToWindow - visibleContentHeight
            containerView.transform = CGAffineTransform(translationX: 0, y: -delta)
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
            containerView.transform = .identity
            return
        }
        scroll.contentInset = .zero
    }
    
    // MARK: - Public -
    
    public func set(returnKeyProvider: @escaping ReturnKeyProviderHandler) {
        guard !handleReturnKeyType else { return }
        self.returnKeyProvider = returnKeyProvider
        assignReturnKeys()
    }
    
    // MARK: - KeyboardHiding -
    
    @objc public func hideKeyboard() {
        textInputs.filter({ $0.isFirstResponder }).forEach { (textInput) in
            textInput.resignFirstResponder()
        }
    }
    
    // MARK: - TextInputsClearing -
    
    
    public func clearTextInputs() {
        textInputs.forEach { textInput in
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
    
    public func reloadTextInputsManager() {
        reset()
        configureManager()
    }
    
    // MARK: - FirstResponding -
    
    public func firstResponder() -> UIView? {
        return textInputs.first(where: { $0.isFirstResponder })
    }
}

// MARK: - UIGestureRecognizerDelegate -

extension TextInputsManager: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tables: [UIView] = containerView.subviewsOf(type: UITableView.self)
        let collections: [UIView] = containerView.subviewsOf(type: UICollectionView.self)
        let subviews: [UIView] = tables + collections
        return !subviews.contains(where: { (subview) -> Bool in
            let point = gestureRecognizer.location(in: subview)
            return subview.point(inside: point, with: nil)
        })
    }
    
}
