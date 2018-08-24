//
//  TextInputsManager.swift
//  SKUtilsSwift
//
//  Created by Sergey Kostyan on 19.07.16.
//  Copyright © 2016 Sergey Kostyan. All rights reserved.
//

import UIKit

open class TextInputsManager: NSObject, KeyboardHiding, TextInputsClearing, TextInputsManagerReloading, FirstResponding, ReturnKeyTypeProviding {
    
    private var textInputs = [UIView]()
    private var containerController: ContainerControlling?
    
    @IBOutlet private weak var containerView: UIView?
    
    @IBInspectable private var hideOnTap: Bool = true
    @IBInspectable private var handleReturnKeyType: Bool = true
    @IBInspectable private var nextBecomesFirstResponder: Bool = true
    @IBInspectable private var additionalSpaceAboveKeyboard: CGFloat = 20.0

    private var currentReturnKeyTypeProvider: ReturnKeyTypeProvider = { (_, isLast) -> UIReturnKeyType in
        guard isLast else { return .next }
        return .done
    }
    
    // MARK: - Lifecycle -
    
    deinit {
        unsubscribeFromAllNotifications()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        guard let containerView = containerView else { return }
        containerController = ContainerControllerFactory().controller(for: containerView)
        configureManager()
        addTapGestureRecognizer(to: containerView, needed: hideOnTap)
    }
    
    // MARK: - Private -
    
    private func configureManager() {
        guard let containerView = containerView else { return }
        subscribeForKeyboardNotifications()
        textInputs = collectTextInputs(in: containerView)
        textInputs.sortByOrigin(convertedTo: UIApplication.shared.keyWindow)
        assignReturnKeys(for: textInputs, with: currentReturnKeyTypeProvider)
    }
    
    private func reset() {
        unsubscribeFromAllNotifications()
        textInputs.removeAll()
    }
    
    // MARK: - Notifications -
    
    private func unsubscribeFromAllNotifications() {
        textInputs.compactMap({ $0 as? UITextView }).forEach { (textView) in
            unsubscribeFromNotifications(for: textView)
        }
        unsubscribeFromKeyboardNotifications()
    }
    
    private func subscribeForKeyboardNotifications() {
        unsubscribeFromKeyboardNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    private func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    private func subscribeForNotifications(for textView: UITextView) {
        unsubscribeFromNotifications(for: textView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidFinishEdititng), name: .UITextViewTextDidEndEditing,
                                               object: textView)
    }
    
    private func unsubscribeFromNotifications(for textView: UITextView) {
        NotificationCenter.default.removeObserver(self, name: .UITextViewTextDidEndEditing, object: textView)
    }
    
    // MARK: - Collecting Views -
    
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
    
    // MARK: - Assign return key type -
    
    private func assignReturnKeys(for textInputs: [UIView], with currentReturnKeyTypeProvider: ReturnKeyTypeProvider) {
        textInputs.compactMap({ $0 as? UITextField }).forEach { (textField) in
            guard let index = textInputs.index(of: textField) else { return }
            let isLast = textInputs.indices.last == index
            textField.returnKeyType = currentReturnKeyTypeProvider(index, isLast)
        }
    }
    
   // MARK: - Gesture Recognizer -
    
    private func addTapGestureRecognizer(to container: UIView, needed: Bool) {
        guard needed else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard), numberOfTapsRequired: 1, delegate: self)
        container.addGestureRecognizer(tap)
    }
    
    // MARK: - Activate next field -
    
    private func activateNext(in textInputs: [UIView], after currentResponder: UIView, canBecomeFirstResponder: Bool) {
        guard canBecomeFirstResponder, let nextResponder = textInputs.nextResponder(after: currentResponder) else {
            hideKeyboard()
            return
        }
        nextResponder.becomeFirstResponder()
    }
    
    // MARK: - Animation -
    
    private func animateKeyboardAction(withInfoFrom notification: Notification, actionHandler: @escaping ((CGRect) -> Void)) {
        guard let userInfo = notification.userInfo,
            let rect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: animationDurarion, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
            actionHandler(rect)
        }, completion: nil)
    }
    
    // MARK: - Private Notifications Selectors -
    
    @objc private func textViewDidFinishEdititng(_ notification: Notification) {
        guard let textView = notification.object as? UIView, textView.isFirstResponder else { return }
        didFinishEdititng(textView)
    }
    
    @objc private func didFinishEdititng(_ textInput: UIView) {
        activateNext(in: textInputs, after: textInput, canBecomeFirstResponder: nextBecomesFirstResponder)
    }
    
    // MARK: - Keyboard notifications -
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        animateKeyboardAction(withInfoFrom: notification) { [weak self] (rect) in
            self?.handleKeyboardAppearance(keyboardFrame: rect)
            self?.moveToActiveTextInput(keyboardFrame: rect)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        animateKeyboardAction(withInfoFrom: notification) { [weak self] (_) in
            self?.handleKeyboardDisappearance()
        }
    }
    
    // MARK: - Behaviour for containerView -
    
    private func moveToActiveTextInput(keyboardFrame rect: CGRect, animated: Bool = false) {
        guard let responder = firstResponder() else { return }
        containerController?.moveTo(responder, keyboardFrame: rect, spaceAboveKeyboard: additionalSpaceAboveKeyboard)
    }
    
    private func handleKeyboardAppearance(keyboardFrame rect: CGRect) {
        containerController?.handleKeyboardAppearance(keyboardFrame: rect)
    }
    
    private func handleKeyboardDisappearance() {
        containerController?.handleKeyboardDisappearance()
    }
    
    // MARK: - KeyboardHiding -
    
    @objc public func hideKeyboard() {
        firstResponder()?.resignFirstResponder()
    }
    
    // MARK: - TextInputsClearing -
    
    public func clearTextInputs() {
        textInputs.forEach { textInput in
            if let textField = textInput as? UITextField {
                textField.clear()
            }
            if let textView = textInput as? UITextView {
                textView.clear()
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
    
    // MARK: - ReturnKeyTypeProviding -
    
    public func set(returnKeyTypeProvider: @escaping ReturnKeyTypeProvider) {
        guard !handleReturnKeyType else { return }
        currentReturnKeyTypeProvider = returnKeyTypeProvider
        assignReturnKeys(for: textInputs, with: currentReturnKeyTypeProvider)
    }
    
}

// MARK: - UIGestureRecognizerDelegate -

extension TextInputsManager: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tables: [UIView] = containerView?.subviewsOf(type: UITableView.self) ?? []
        let collections: [UIView] = containerView?.subviewsOf(type: UICollectionView.self) ?? []
        let subviews: [UIView] = tables + collections
        return !subviews.contains(where: { (subview) -> Bool in
            let point = gestureRecognizer.location(in: subview)
            return subview.point(inside: point, with: nil)
        })
    }
    
}
