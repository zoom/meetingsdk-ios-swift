//
//  Custom3DAvatarEditViewController.swift
//  MobileRTCSwiftSample
//
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Creates or edits a single custom 3D avatar by configuring its element images
/// and colors. Swift port of the Objective-C `Custom3DAvatarEditViewController`.
final class Custom3DAvatarEditViewController: UIViewController,
                                              UICollectionViewDataSource,
                                              UICollectionViewDelegate,
                                              UIPickerViewDataSource,
                                              UIPickerViewDelegate,
                                              MobileRTCMeetingSettingsDelegate,
                                              MobileRTCCustom3DAvatarElementSettingContextDelegate {

    enum Mode {
        case create
        case edit
    }

    /// One selectable element category shown in the type picker.
    private struct ElementTypeItem {
        let imageType: MobileRTCCustom3DAvatarElementImageType
        let displayName: String
    }

    // Layout constants (mirror the Objective-C sample).
    private let previewHeight: CGFloat = 300
    private let collectionHeight: CGFloat = 150
    private let spacing: CGFloat = 20
    private let typeButtonHeight: CGFloat = 44
    private let pickerHeight: CGFloat = 200

    private let mode: Mode
    private let editAvatarInfo: MobileRTC3DAvatarImageInfo?

    private let previewView = UIView()
    private let typeSelectionButton = UIButton(type: .system)
    private let pickerBackgroundView = UIView()
    private let pickerContainerView = UIView()
    private let typePickerView = UIPickerView()
    private var imageElementCollectionView: UICollectionView!
    private var colorElementCollectionView: UICollectionView!

    private var elementContext: MobileRTCCustom3DAvatarElementSettingContext?
    /// Element image waiting for its model data to finish downloading before being applied.
    private var pendingElementToSet: MobileRTCCustom3DAvatarElementImageInfo?

    private var allImageElementList: [MobileRTCCustom3DAvatarElementImageInfo] = []
    private var allColorElementList: [MobileRTCCustom3DAvatarElementColorInfo] = []
    private var filteredImageElementList: [MobileRTCCustom3DAvatarElementImageInfo] = []
    private var filteredColorElementList: [MobileRTCCustom3DAvatarElementColorInfo] = []

    private let availableTypes: [ElementTypeItem] = [
        ElementTypeItem(imageType: .none, displayName: "None"),
        ElementTypeItem(imageType: .skin, displayName: "Skin"),
        ElementTypeItem(imageType: .face, displayName: "Face"),
        ElementTypeItem(imageType: .hair, displayName: "Hair"),
        ElementTypeItem(imageType: .eyes, displayName: "Eyes"),
        ElementTypeItem(imageType: .eyeColor, displayName: "EyeColor"),
        ElementTypeItem(imageType: .eyelashes, displayName: "Eyelashes"),
        ElementTypeItem(imageType: .eyebrows, displayName: "Eyebrows"),
        ElementTypeItem(imageType: .nose, displayName: "Nose"),
        ElementTypeItem(imageType: .mouth, displayName: "Mouth"),
        ElementTypeItem(imageType: .lipColor, displayName: "LipColor"),
        ElementTypeItem(imageType: .age, displayName: "Age"),
        ElementTypeItem(imageType: .facialHair, displayName: "FacialHair"),
        ElementTypeItem(imageType: .body, displayName: "Body"),
        ElementTypeItem(imageType: .clothing, displayName: "Clothing"),
        ElementTypeItem(imageType: .headCovering, displayName: "HeadCovering"),
        ElementTypeItem(imageType: .glasses, displayName: "Glasses"),
    ]
    private var selectedType: ElementTypeItem?

    /// Maps an element image type to the color type that applies to it.
    private let typeMapping: [MobileRTCCustom3DAvatarElementImageType: MobileRTCCustom3DAvatarElementColorType] = [
        .eyebrows: .eyebrow,
        .facialHair: .mustache,
        .hair: .hair,
        .eyelashes: .eyelash,
    ]

    private weak var downloadingAlert: UIAlertController?
    private var downloadTimeoutTimer: Timer?

    private var settings: MobileRTCMeetingSettings? {
        MobileRTC.shared().getMeetingSettings()
    }

    // MARK: - Init

    init(mode: Mode, avatarInfo: MobileRTC3DAvatarImageInfo? = nil) {
        self.mode = mode
        self.editAvatarInfo = avatarInfo
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = mode == .create ? "New Custom 3D Avatar" : "Edit Custom 3D Avatar"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(onCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                           target: self, action: #selector(onConfirm))
        setupUI()
        // Avatar model-data download callbacks arrive via MobileRTCMeetingSettingsDelegate
        // (set in initializeContext) and the element context delegate — not the meeting
        // service delegate, which the meeting presenter owns.
        initializeContext()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !pickerBackgroundView.isHidden {
            hidePickerView()
        }
        downloadTimeoutTimer?.invalidate()
        downloadTimeoutTimer = nil
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        pickerBackgroundView.frame = view.bounds
    }

    deinit {
        downloadTimeoutTimer?.invalidate()
    }

    // MARK: - UI setup

    private func setupUI() {
        let screenWidth = view.bounds.size.width
        let screenHeight = view.bounds.size.height

        previewView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: previewHeight)
        previewView.backgroundColor = .black
        view.addSubview(previewView)

        typeSelectionButton.frame = CGRect(x: 0, y: previewHeight + spacing, width: screenWidth, height: typeButtonHeight)
        typeSelectionButton.setTitle("Select Type", for: .normal)
        typeSelectionButton.setTitleColor(.label, for: .normal)
        typeSelectionButton.backgroundColor = .systemGray4
        typeSelectionButton.addTarget(self, action: #selector(onTypeSelectionButtonTapped), for: .touchUpInside)
        view.addSubview(typeSelectionButton)

        // Semi-transparent overlay shown behind the picker.
        pickerBackgroundView.frame = view.bounds
        pickerBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        pickerBackgroundView.isHidden = true
        pickerBackgroundView.alpha = 0
        pickerBackgroundView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onPickerBackgroundTapped))
        )
        view.addSubview(pickerBackgroundView)

        // Picker sheet (off-screen until shown).
        pickerContainerView.frame = CGRect(x: 0, y: screenHeight, width: screenWidth, height: pickerHeight)
        pickerContainerView.backgroundColor = .systemBackground
        pickerContainerView.layer.cornerRadius = 10
        pickerContainerView.layer.masksToBounds = true

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onPickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        pickerContainerView.addSubview(toolbar)

        typePickerView.frame = CGRect(x: 0, y: 44, width: screenWidth, height: pickerHeight - 44)
        typePickerView.dataSource = self
        typePickerView.delegate = self
        typePickerView.backgroundColor = .systemBackground
        pickerContainerView.addSubview(typePickerView)
        view.addSubview(pickerContainerView)

        let imageCollectionY = previewHeight + spacing + typeButtonHeight + spacing
        imageElementCollectionView = makeHorizontalCollectionView(
            frame: CGRect(x: 0, y: imageCollectionY, width: screenWidth, height: collectionHeight),
            reuseIdentifier: "ImageElementCell"
        )
        view.addSubview(imageElementCollectionView)

        let colorCollectionY = imageCollectionY + collectionHeight + spacing
        colorElementCollectionView = makeHorizontalCollectionView(
            frame: CGRect(x: 0, y: colorCollectionY, width: screenWidth, height: collectionHeight),
            reuseIdentifier: "ColorElementCell"
        )
        view.addSubview(colorElementCollectionView)
    }

    private func makeHorizontalCollectionView(frame: CGRect, reuseIdentifier: String) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray5
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        return collectionView
    }

    // MARK: - Context

    private func initializeContext() {
        guard let settings else {
            showError("Settings not available")
            return
        }
        settings.setDelegate(self)

        switch mode {
        case .create:
            elementContext = settings.startCreateCustom3DAvatar(withPreviewView: previewView)
            if elementContext == nil {
                if !settings.isCustom3DAvatarDefaultImageModelDataReady() {
                    showDownloadingAlert()
                    if settings.downloadCustom3DAvatarDefaultImageModelData() != .success {
                        dismissDownloadingAlert()
                        showError("Failed to start download")
                    }
                } else {
                    showError("Failed to begin create")
                }
                return
            }
        case .edit:
            guard let editAvatarInfo else {
                showError("Avatar info not available")
                return
            }
            elementContext = settings.startEditCustom3DAvatar(withPreviewView: previewView, imageInfo: editAvatarInfo)
            if elementContext == nil {
                if !settings.isCustom3DAvatarImageModelDataReady(editAvatarInfo) {
                    showDownloadingAlert()
                    if settings.downloadCustom3DAvatarImageModelData(editAvatarInfo) != .success {
                        dismissDownloadingAlert()
                        showError("Failed to start download")
                    }
                } else {
                    showError("Failed to begin edit")
                }
                return
            }
        }

        if let elementContext {
            elementContext.setDelegate(self)
        }
        loadElementLists()
    }

    private func loadElementLists() {
        guard let elementContext else { return }
        allImageElementList = elementContext.getCustom3DAvatarElementImageList() ?? []
        allColorElementList = elementContext.getCustom3DAvatarElementColorList() ?? []

        // Default to the first non-None type that actually has elements.
        if selectedType == nil, !allImageElementList.isEmpty {
            selectedType = availableTypes.first { type in
                type.imageType != .none
                    && allImageElementList.contains { $0.elementImageType == type.imageType }
            }
        }
        updateTypeSelection()
    }

    private func filterElementLists() {
        guard let selectedType else {
            filteredImageElementList = allImageElementList
            filteredColorElementList = allColorElementList
            return
        }

        if selectedType.imageType != .none {
            filteredImageElementList = allImageElementList.filter { $0.elementImageType == selectedType.imageType }
        } else {
            filteredImageElementList = []
        }

        if let mappedColorType = typeMapping[selectedType.imageType], mappedColorType != .none {
            filteredColorElementList = allColorElementList.filter { $0.elementColorType == mappedColorType }
        } else {
            filteredColorElementList = []
        }
    }

    private func updateTypeSelection() {
        if let selectedType {
            typeSelectionButton.setTitle(selectedType.displayName, for: .normal)
        }
        filterElementLists()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.imageElementCollectionView.reloadData()
            self.colorElementCollectionView.reloadData()
            self.updateCollectionViewLayout()
        }
    }

    private func updateCollectionViewLayout() {
        let screenWidth = view.bounds.size.width
        let imageCollectionY = previewHeight + spacing + typeButtonHeight + spacing
        imageElementCollectionView.frame = CGRect(x: 0, y: imageCollectionY, width: screenWidth, height: collectionHeight)

        if filteredColorElementList.isEmpty {
            colorElementCollectionView.isHidden = true
        } else {
            colorElementCollectionView.isHidden = false
            let colorCollectionY = imageCollectionY + collectionHeight + spacing
            colorElementCollectionView.frame = CGRect(x: 0, y: colorCollectionY, width: screenWidth, height: collectionHeight)
        }
    }

    // MARK: - Downloading alert / timeout

    private func showDownloadingAlert() {
        downloadingAlert?.dismiss(animated: false)
        downloadTimeoutTimer?.invalidate()

        let alert = UIAlertController(title: "Downloading",
                                      message: "Downloading avatar elements, please wait...",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.handleDownloadCancelled()
        })
        downloadingAlert = alert
        present(alert, animated: true)

        downloadTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
            self?.handleDownloadTimeout()
        }
    }

    private func handleDownloadCancelled() {
        downloadTimeoutTimer?.invalidate()
        downloadTimeoutTimer = nil
        downloadingAlert?.dismiss(animated: true)
        downloadingAlert = nil
        navigationController?.popViewController(animated: true)
    }

    private func handleDownloadTimeout() {
        downloadTimeoutTimer?.invalidate()
        downloadTimeoutTimer = nil
        guard let alert = downloadingAlert else { return }
        alert.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.downloadingAlert = nil
            let timeoutAlert = UIAlertController(
                title: "Timeout",
                message: "Download timeout. Please check your network connection and try again.",
                preferredStyle: .alert
            )
            timeoutAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            self.present(timeoutAlert, animated: true)
        }
    }

    private func dismissDownloadingAlert() {
        downloadTimeoutTimer?.invalidate()
        downloadTimeoutTimer = nil
        downloadingAlert?.dismiss(animated: true)
        downloadingAlert = nil
    }

    // MARK: - Picker show / hide

    @objc private func onTypeSelectionButtonTapped() {
        showPickerView()
    }

    private func showPickerView() {
        if let selectedType, let index = availableTypes.firstIndex(where: { $0.imageType == selectedType.imageType }) {
            typePickerView.selectRow(index, inComponent: 0, animated: false)
        }
        pickerBackgroundView.isHidden = false
        view.bringSubviewToFront(pickerBackgroundView)
        view.bringSubviewToFront(pickerContainerView)

        let screenHeight = view.bounds.size.height
        UIView.animate(withDuration: 0.3) {
            self.pickerBackgroundView.alpha = 1
            self.pickerContainerView.frame = CGRect(x: 0, y: screenHeight - self.pickerHeight,
                                                    width: self.view.bounds.size.width, height: self.pickerHeight)
        }
        setControlsEnabled(false)
    }

    private func hidePickerView() {
        let screenHeight = view.bounds.size.height
        UIView.animate(withDuration: 0.3, animations: {
            self.pickerBackgroundView.alpha = 0
            self.pickerContainerView.frame = CGRect(x: 0, y: screenHeight,
                                                    width: self.view.bounds.size.width, height: self.pickerHeight)
        }, completion: { _ in
            self.pickerBackgroundView.isHidden = true
            self.setControlsEnabled(true)
        })
    }

    private func setControlsEnabled(_ enabled: Bool) {
        typeSelectionButton.isEnabled = enabled
        imageElementCollectionView.isUserInteractionEnabled = enabled
        colorElementCollectionView.isUserInteractionEnabled = enabled
        navigationItem.leftBarButtonItem?.isEnabled = enabled
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    @objc private func onPickerDone() {
        hidePickerView()
    }

    @objc private func onPickerBackgroundTapped() {
        hidePickerView()
    }

    // MARK: - Save / cancel

    @objc private func onCancel() {
        finish(save: false)
    }

    @objc private func onConfirm() {
        finish(save: true)
    }

    private func finish(save: Bool) {
        guard let settings else {
            showError("Settings not available")
            return
        }
        let error = mode == .create
            ? settings.finishCreateCustom3DAvatar(save)
            : settings.finishEditCustom3DAvatar(save)
        if error == .success {
            navigationController?.popViewController(animated: true)
        } else {
            showError("Failed to save: \(error.rawValue)")
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == imageElementCollectionView {
            return filteredImageElementList.count
        } else {
            return filteredColorElementList.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageElementCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageElementCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let imageInfo = filteredImageElementList[indexPath.item]
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0,
                                                      width: cell.bounds.width, height: cell.bounds.height - 20))
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.backgroundColor = .systemGray4
            if let path = imageInfo.imageFilePath, !path.isEmpty {
                imageView.image = UIImage(contentsOfFile: path)
            }
            imageView.layer.borderWidth = imageInfo.isSelected ? 3 : 1
            imageView.layer.borderColor = (imageInfo.isSelected ? UIColor.systemBlue : UIColor.black).cgColor
            cell.contentView.addSubview(imageView)

            cell.contentView.addSubview(makeCaptionLabel(text: imageInfo.imageName ?? "Image \(indexPath.item)",
                                                         in: cell.bounds))
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorElementCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let colorInfo = filteredColorElementList[indexPath.item]
            let colorView = UIView(frame: cell.bounds)
            colorView.backgroundColor = colorInfo.color ?? .systemGray
            colorView.layer.borderWidth = colorInfo.isSelected ? 3 : 1
            colorView.layer.borderColor = (colorInfo.isSelected ? UIColor.systemBlue : UIColor.black).cgColor
            cell.contentView.addSubview(colorView)

            cell.contentView.addSubview(makeCaptionLabel(text: colorInfo.colorName ?? "Color \(indexPath.item)",
                                                         in: cell.bounds))
            return cell
        }
    }

    private func makeCaptionLabel(text: String, in bounds: CGRect) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: bounds.height - 20, width: bounds.width, height: 20))
        label.text = text
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        label.backgroundColor = .white
        label.textColor = .black
        return label
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let elementContext else { return }

        if collectionView == imageElementCollectionView {
            let imageInfo = filteredImageElementList[indexPath.item]
            if elementContext.isCustom3DAvatarElementImageModelDataReady(imageInfo) {
                let error = elementContext.setCustom3DAvatarElementImage(imageInfo)
                if error == .success {
                    loadElementLists()
                } else {
                    showError("Failed to set image: \(error.rawValue)")
                }
            } else {
                pendingElementToSet = imageInfo
                let error = elementContext.downloadCustom3dAvatarElementImageModelData(imageInfo)
                if error != .success {
                    pendingElementToSet = nil
                    showError("Failed to start download: \(error.rawValue)")
                } else {
                    Logger.info("Downloading element image data...")
                }
            }
        } else {
            let colorInfo = filteredColorElementList[indexPath.item]
            let error = elementContext.setCustom3DAvatarElementColor(colorInfo)
            if error == .success {
                loadElementLists()
            } else {
                showError("Failed to set color: \(error.rawValue)")
            }
        }
    }

    // MARK: - UIPickerViewDataSource / Delegate

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        availableTypes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        availableTypes[row].displayName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedType = availableTypes[row]
        updateTypeSelection()
    }

    // MARK: - MobileRTCCustom3DAvatarElementSettingContextDelegate

    func onCustom3DAvatarElementImageModelDataDownloaded(_ success: Bool,
                                                         imageInfo: MobileRTCCustom3DAvatarElementImageInfo) {
        Logger.info("onCustom3DAvatarElementImageModelDataDownloaded success=\(success)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard success else {
                self.pendingElementToSet = nil
                self.showError("Failed to download element image data")
                return
            }
            if let pending = self.pendingElementToSet, let elementContext = self.elementContext {
                let error = elementContext.setCustom3DAvatarElementImage(pending)
                if error == .success {
                    self.loadElementLists()
                } else {
                    self.showError("Failed to set image: \(error.rawValue)")
                }
            }
            self.pendingElementToSet = nil
        }
    }

    // MARK: - MobileRTCMeetingSettingsDelegate

    func onCustom3DAvatarDefaultImageModelDataDownloaded(_ success: Bool) {
        Logger.info("onCustom3DAvatarDefaultImageModelDataDownloaded success=\(success)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.dismissDownloadingAlert()
            if success, self.mode == .create, self.elementContext == nil {
                self.initializeContext()
            } else if !success {
                self.showDownloadFailedAlert()
            }
        }
    }

    func onCustom3DAvatarImageModelDataDownloaded(_ success: Bool, imageInfo: MobileRTC3DAvatarImageInfo?) {
        Logger.info("onCustom3DAvatarImageModelDataDownloaded success=\(success)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.dismissDownloadingAlert()
            if success, self.mode == .edit, self.elementContext == nil {
                self.initializeContext()
            } else if !success {
                self.showDownloadFailedAlert()
            }
        }
    }

    private func showDownloadFailedAlert() {
        let alert = UIAlertController(
            title: "Download Failed",
            message: "Failed to download avatar data. Please check your network connection and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
