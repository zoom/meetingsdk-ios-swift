//
//  PreviewViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// A pre-join preview screen allowing the user to configure display name,
/// audio mute state, video mute state, and virtual background before joining.
final class PreviewViewController: UIViewController {

    private let handler: MobileRTCJoinMeetingInfoHandler
    private let suggestedName: String

    // Preview
    private let previewVideoView = MobileRTCPreviewVideoView()
    private let vbPreviewContainer = UIView()
    private let videoOffLabel = UILabel()

    // State
    private var videoOn: Bool = true
    private var audioOn: Bool = true

    // Controls
    private let nameField = UITextField()
    private let videoButton = UIButton(type: .system)
    private let audioButton = UIButton(type: .system)
    private let vbButton = UIButton(type: .system)
    private let controlBar = UIView()
    private let fieldContainer = UIView()

    // VB picker
    private var vbItems: [MobileRTCVirtualBGImageInfo] = []
    private let vbPanel = UIView()
    private lazy var vbCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 60)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(VBItemCell.self, forCellWithReuseIdentifier: VBItemCell.reuseID)
        return cv
    }()

    init(handler: MobileRTCJoinMeetingInfoHandler, displayName: String?) {
        self.handler = handler
        self.suggestedName = displayName ?? ""
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupPreviewArea()
        setupControlBar()
        setupNameField()
        setupJoinCancelButtons()
        setupVBPanel()
        loadVBItems()
        startPreview()
        updateVideoButton()
        updateAudioButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _ = MobileRTC.shared().getMeetingService()?.stopPreview()
    }

    // MARK: Setup

    private func setupPreviewArea() {
        previewVideoView.translatesAutoresizingMaskIntoConstraints = false
        previewVideoView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        previewVideoView.layer.cornerRadius = 12
        previewVideoView.clipsToBounds = true
        view.addSubview(previewVideoView)

        vbPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        vbPreviewContainer.backgroundColor = UIColor(white: 0.1, alpha: 1)
        vbPreviewContainer.layer.cornerRadius = 12
        vbPreviewContainer.clipsToBounds = true
        vbPreviewContainer.isHidden = true
        view.addSubview(vbPreviewContainer)

        let aspect = previewVideoView.heightAnchor.constraint(
            equalTo: previewVideoView.widthAnchor, multiplier: 9.0 / 16.0
        )
        aspect.priority = .defaultHigh
        let maxHeight: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 500 : 1000

        NSLayoutConstraint.activate([
            previewVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            aspect,
            previewVideoView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight),

            vbPreviewContainer.topAnchor.constraint(equalTo: previewVideoView.topAnchor),
            vbPreviewContainer.leadingAnchor.constraint(equalTo: previewVideoView.leadingAnchor),
            vbPreviewContainer.trailingAnchor.constraint(equalTo: previewVideoView.trailingAnchor),
            vbPreviewContainer.bottomAnchor.constraint(equalTo: previewVideoView.bottomAnchor),
        ])

        videoOffLabel.text = "Camera is off"
        videoOffLabel.textColor = UIColor(white: 0.6, alpha: 1)
        videoOffLabel.font = .systemFont(ofSize: 16)
        videoOffLabel.textAlignment = .center
        videoOffLabel.translatesAutoresizingMaskIntoConstraints = false
        videoOffLabel.isHidden = true
        previewVideoView.addSubview(videoOffLabel)
        NSLayoutConstraint.activate([
            videoOffLabel.centerXAnchor.constraint(equalTo: previewVideoView.centerXAnchor),
            videoOffLabel.centerYAnchor.constraint(equalTo: previewVideoView.centerYAnchor),
        ])
    }

    private func setupControlBar() {
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlBar)

        configureIconButton(videoButton, systemImage: "video.fill", action: #selector(onToggleVideo))
        configureIconButton(audioButton, systemImage: "mic.fill", action: #selector(onToggleAudio))
        configureIconButton(vbButton, systemImage: "sparkles.rectangle.stack.fill", action: #selector(onToggleVB))

        let videoStack = makeButtonStack(button: videoButton, title: "Video")
        let audioStack = makeButtonStack(button: audioButton, title: "Audio")
        let vbStack = makeButtonStack(button: vbButton, title: "Background")

        let row = UIStackView(arrangedSubviews: [audioStack, videoStack, vbStack])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(row)

        NSLayoutConstraint.activate([
            controlBar.topAnchor.constraint(equalTo: previewVideoView.bottomAnchor, constant: 16),
            controlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlBar.heightAnchor.constraint(equalToConstant: 64),
            row.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            row.topAnchor.constraint(equalTo: controlBar.topAnchor),
            row.bottomAnchor.constraint(equalTo: controlBar.bottomAnchor),
        ])
    }

    private func setupNameField() {
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.backgroundColor = UIColor(white: 0.2, alpha: 1)
        fieldContainer.layer.cornerRadius = 10
        view.addSubview(fieldContainer)

        let nameIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        nameIcon.tintColor = UIColor(white: 0.6, alpha: 1)
        nameIcon.contentMode = .scaleAspectFit
        nameIcon.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.addSubview(nameIcon)

        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.text = suggestedName
        nameField.textColor = .white
        nameField.font = .systemFont(ofSize: 16)
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.attributedPlaceholder = NSAttributedString(
            string: "Display Name",
            attributes: [.foregroundColor: UIColor(white: 0.5, alpha: 1)]
        )
        fieldContainer.addSubview(nameField)

        NSLayoutConstraint.activate([
            fieldContainer.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 16),
            fieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fieldContainer.heightAnchor.constraint(equalToConstant: 48),

            nameIcon.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            nameIcon.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            nameIcon.widthAnchor.constraint(equalToConstant: 20),
            nameIcon.heightAnchor.constraint(equalToConstant: 20),

            nameField.leadingAnchor.constraint(equalTo: nameIcon.trailingAnchor, constant: 8),
            nameField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -12),
            nameField.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            nameField.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),
        ])
    }

    private func setupJoinCancelButtons() {
        let joinButton = UIButton(type: .system)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.backgroundColor = .systemBlue
        joinButton.layer.cornerRadius = 12
        joinButton.setTitle("Join Meeting", for: .normal)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        joinButton.addTarget(self, action: #selector(onJoin), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.backgroundColor = UIColor(white: 0.25, alpha: 1)
        cancelButton.layer.cornerRadius = 12
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(white: 0.8, alpha: 1), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [cancelButton, joinButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let kButtonHeight: CGFloat = 52
        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.heightAnchor.constraint(equalToConstant: kButtonHeight),
            joinButton.heightAnchor.constraint(equalToConstant: kButtonHeight),
            cancelButton.heightAnchor.constraint(equalToConstant: kButtonHeight),
            fieldContainer.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -16),
        ])
    }

    private func setupVBPanel() {
        vbPanel.translatesAutoresizingMaskIntoConstraints = false
        vbPanel.backgroundColor = UIColor(white: 0.12, alpha: 0.97)
        vbPanel.layer.cornerRadius = 16
        vbPanel.isHidden = true
        view.addSubview(vbPanel)

        let vbTitle = UILabel()
        vbTitle.text = "Virtual Background"
        vbTitle.textColor = .white
        vbTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        vbTitle.translatesAutoresizingMaskIntoConstraints = false
        vbPanel.addSubview(vbTitle)

        vbCollectionView.translatesAutoresizingMaskIntoConstraints = false
        vbCollectionView.dataSource = self
        vbCollectionView.delegate = self
        vbPanel.addSubview(vbCollectionView)

        NSLayoutConstraint.activate([
            vbPanel.bottomAnchor.constraint(equalTo: controlBar.topAnchor, constant: -8),
            vbPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            vbPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            vbPanel.heightAnchor.constraint(equalToConstant: 110),

            vbTitle.topAnchor.constraint(equalTo: vbPanel.topAnchor, constant: 10),
            vbTitle.leadingAnchor.constraint(equalTo: vbPanel.leadingAnchor, constant: 12),

            vbCollectionView.topAnchor.constraint(equalTo: vbTitle.bottomAnchor, constant: 8),
            vbCollectionView.leadingAnchor.constraint(equalTo: vbPanel.leadingAnchor, constant: 8),
            vbCollectionView.trailingAnchor.constraint(equalTo: vbPanel.trailingAnchor, constant: -8),
            vbCollectionView.bottomAnchor.constraint(equalTo: vbPanel.bottomAnchor, constant: -10),
        ])
    }

    // MARK: Preview

    private func startPreview() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isSupportVirtualBG() {
            _ = ms.startPreview(withFrame: vbPreviewContainer.bounds)
            if let previewView = ms.previewView {
                previewView.frame = vbPreviewContainer.bounds
                previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                vbPreviewContainer.addSubview(previewView)
                vbPreviewContainer.isHidden = false
                previewVideoView.isHidden = true
                return
            }
        }
        previewVideoView.isHidden = false
        vbPreviewContainer.isHidden = true
    }

    private func updateVideoOffPlaceholder() {
        videoOffLabel.isHidden = videoOn
    }

    // MARK: VB Data

    private func loadVBItems() {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isSupportVirtualBG() else {
            vbItems = []
            vbCollectionView.reloadData()
            return
        }
        vbItems = ms.getBGImageList() ?? []
        vbCollectionView.reloadData()
        if let idx = vbItems.firstIndex(where: { $0.isSelect }) {
            vbCollectionView.selectItem(
                at: IndexPath(item: idx, section: 0), animated: false, scrollPosition: []
            )
        }
    }

    // MARK: Actions

    @objc private func onToggleVideo() {
        videoOn.toggle()
        updateVideoButton()
        updateVideoOffPlaceholder()
    }

    @objc private func onToggleAudio() {
        audioOn.toggle()
        updateAudioButton()
    }

    @objc private func onToggleVB() {
        let willShow = vbPanel.isHidden
        UIView.animate(withDuration: 0.2) {
            self.vbPanel.isHidden = !willShow
            self.vbPanel.alpha = willShow ? 1.0 : 0.0
        }
    }

    @objc private func onJoin() {
        let trimmed = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            shakeNameField()
            return
        }
        _ = handler.confirmPreview(trimmed, videoOn: videoOn, audioOn: audioOn)
        dismiss(animated: true)
    }

    @objc private func onCancel() {
        handler.cancel()
        dismiss(animated: true)
    }

    // MARK: Button state

    private func updateVideoButton() {
        let imageName = videoOn ? "video.fill" : "video.slash.fill"
        videoButton.setImage(UIImage(systemName: imageName), for: .normal)
        videoButton.tintColor = videoOn ? .white : .systemRed
        videoButton.backgroundColor = videoOn
            ? UIColor(white: 0.28, alpha: 1)
            : UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.3)
    }

    private func updateAudioButton() {
        let imageName = audioOn ? "mic.fill" : "mic.slash.fill"
        audioButton.setImage(UIImage(systemName: imageName), for: .normal)
        audioButton.tintColor = audioOn ? .white : .systemRed
        audioButton.backgroundColor = audioOn
            ? UIColor(white: 0.28, alpha: 1)
            : UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.3)
    }

    // MARK: Helpers

    private func configureIconButton(_ button: UIButton, systemImage: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.28, alpha: 1)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func makeButtonStack(button: UIButton, title: String) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.textColor = UIColor(white: 0.7, alpha: 1)
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [button, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }

    private func shakeNameField() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: .linear)
        shake.duration = 0.4
        shake.values = [-8, 8, -6, 6, -4, 4, 0]
        nameField.layer.add(shake, forKey: "shake")
        nameField.layer.borderWidth = 1.0
        nameField.layer.borderColor = UIColor.systemRed.cgColor
        nameField.layer.cornerRadius = 6
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.nameField.layer.borderWidth = 0
        }
    }
}

// MARK: - UITextFieldDelegate

extension PreviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionView data source / delegate

extension PreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        vbItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VBItemCell.reuseID, for: indexPath)
        guard let vbCell = cell as? VBItemCell else { return cell }
        let item = vbItems[indexPath.item]
        switch item.vbType {
        case .none:
            vbCell.titleLabel.text = "None"
            vbCell.thumbnailView.image = nil
            vbCell.contentView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        case .blur:
            vbCell.titleLabel.text = "Blur"
            vbCell.thumbnailView.image = UIImage(systemName: "drop.fill")
            vbCell.thumbnailView.tintColor = .systemCyan
            vbCell.contentView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        case .item:
            vbCell.titleLabel.text = ""
            if let path = item.imagePath {
                vbCell.thumbnailView.image = UIImage(contentsOfFile: path)
            }
            vbCell.contentView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        @unknown default:
            break
        }
        vbCell.isSelected = item.isSelect
        return vbCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        _ = ms.useBGImage(vbItems[indexPath.item])
        collectionView.reloadData()
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }
}

// MARK: - VBItemCell

private final class VBItemCell: UICollectionViewCell {
    static let reuseID = "VBItemCell"

    let thumbnailView = UIImageView()
    let titleLabel = UILabel()
    private let selectionRing = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1)

        thumbnailView.frame = contentView.bounds
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(thumbnailView)

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        selectionRing.layer.cornerRadius = 8
        selectionRing.layer.borderWidth = 2.5
        selectionRing.layer.borderColor = UIColor.systemBlue.cgColor
        selectionRing.isHidden = true
        selectionRing.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectionRing)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            selectionRing.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionRing.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionRing.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionRing.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isSelected: Bool {
        didSet { selectionRing.isHidden = !isSelected }
    }
}
