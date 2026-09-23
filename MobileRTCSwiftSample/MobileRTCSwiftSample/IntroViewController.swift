//
//  IntroViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import UIKit

private enum Tag {
    static let titleLabel = 1
    static let imageView = 2
    static let detailLabel = 3
}

private enum IntroLayout {
    static let pageCount = 4
    /// Title Y uses `titlePortraitLineCount × kPageHeight` in portrait / iPad vs `kPageHeight` in landscape phone.
    static let titlePortraitLineCount: CGFloat = 3
}

private enum IntroColors {
    static let bodyText = UIColor(red: 57 / 255, green: 57 / 255, blue: 57 / 255, alpha: 1)
    static let pageIndicatorCurrent = UIColor(red: 128 / 255, green: 128 / 255, blue: 148 / 255, alpha: 1)
    static let pageIndicatorNormal = UIColor(red: 228 / 255, green: 228 / 255, blue: 238 / 255, alpha: 1)
}

private enum IntroTypography {
    static let title: CGFloat = 18
    static let titlePad: CGFloat = 32
    static let detail: CGFloat = 12
    static let detailPad: CGFloat = 20
}

/// Paged onboarding: `UIScrollView` + `zoom_intro1`…`zoom_intro4` from the asset catalog or bundle.
final class IntroViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let firstView = UIView()
    private let secondView = UIView()
    private let thirdView = UIView()
    private let fourthView = UIView()

    private let kPageHeight: CGFloat = 20
    private let kTitleHeight: CGFloat = 24
    private let kPadTitleHeight: CGFloat = 60
    private let kDetailHeight: CGFloat = 30

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private let titleFont = UIFont(name: "HelveticaNeue-Bold", size: IntroTypography.title) ?? .boldSystemFont(ofSize: IntroTypography.title)
    private let titlePadFont = UIFont(name: "HelveticaNeue-Bold", size: IntroTypography.titlePad) ?? .boldSystemFont(ofSize: IntroTypography.titlePad)
    private let detailFont = UIFont(name: "HelveticaNeue", size: IntroTypography.detail) ?? .systemFont(ofSize: IntroTypography.detail)
    private let detailPadFont = UIFont(name: "HelveticaNeue", size: IntroTypography.detailPad) ?? .systemFont(ofSize: IntroTypography.detailPad)

    private let textColor = IntroColors.bodyText

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        pageControl.isUserInteractionEnabled = false
        pageControl.currentPageIndicatorTintColor = IntroColors.pageIndicatorCurrent
        pageControl.pageIndicatorTintColor = IntroColors.pageIndicatorNormal
        pageControl.numberOfPages = IntroLayout.pageCount

        view.addSubview(scrollView)
        scrollView.addSubview(firstView)
        scrollView.addSubview(secondView)
        scrollView.addSubview(thirdView)
        scrollView.addSubview(fourthView)
        view.addSubview(pageControl)

        buildPage(
            firstView,
            imageName: "zoom_intro1",
            title: NSLocalizedString("Start a Meeting", comment: ""),
            detail: NSLocalizedString("Start or join a video meeting on the go", comment: "")
        )
        buildPage(
            secondView,
            imageName: "zoom_intro2",
            title: NSLocalizedString("Share Your Content", comment: ""),
            detail: NSLocalizedString("They see what you see", comment: "")
        )
        buildPage(
            thirdView,
            imageName: "zoom_intro3",
            title: NSLocalizedString("Message Your Team", comment: ""),
            detail: NSLocalizedString("Send texts, voice messages, files and images", comment: "")
        )
        buildPage(
            fourthView,
            imageName: "zoom_intro4",
            title: NSLocalizedString("Get Meeting!", comment: ""),
            detail: NSLocalizedString("Work anywhere, with anyone, on any device", comment: "")
        )
    }

    private func buildPage(_ page: UIView, imageName: String, title: String, detail: String) {
        let imageView = UIImageView()
        imageView.tag = Tag.imageView
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: imageName) ?? UIImage(named: "\(imageName).png")
        page.addSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.tag = Tag.titleLabel
        titleLabel.text = title
        titleLabel.font = isPad ? titlePadFont : titleFont
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = textColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        page.addSubview(titleLabel)

        let detailLabel = UILabel()
        detailLabel.tag = Tag.detailLabel
        detailLabel.text = detail
        detailLabel.font = isPad ? detailPadFont : detailFont
        detailLabel.backgroundColor = .clear
        detailLabel.textColor = textColor
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        page.addSubview(detailLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.bounds
        let portrait = bounds.height > bounds.width
        let safeBottom = view.safeAreaInsets.bottom
        pageControl.frame = CGRect(
            x: 0,
            y: bounds.height - kPageHeight - safeBottom,
            width: bounds.width,
            height: kPageHeight
        )

        scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        scrollView.contentSize = CGSize(width: bounds.width * CGFloat(pageControl.numberOfPages), height: scrollView.frame.height)

        layoutFirstPage(portrait: portrait)
        layoutSecondPage(portrait: portrait)
        layoutThirdPage(portrait: portrait)
        layoutFourthPage(portrait: portrait)
    }

    private func titleOffsetY(portrait: Bool) -> CGFloat {
        (isPad || portrait) ? IntroLayout.titlePortraitLineCount * kPageHeight : kPageHeight
    }

    private func layoutFirstPage(portrait: Bool) {
        let viewFrame = view.bounds
        firstView.frame = viewFrame
        layoutLabelsAndImage(in: firstView, pageFrame: viewFrame, portrait: portrait)
    }

    private func layoutSecondPage(portrait: Bool) {
        let viewFrame = firstView.frame.offsetBy(dx: firstView.frame.width, dy: 0)
        secondView.frame = viewFrame
        layoutLabelsAndImage(in: secondView, pageFrame: viewFrame, portrait: portrait)
    }

    private func layoutThirdPage(portrait: Bool) {
        let viewFrame = secondView.frame.offsetBy(dx: secondView.frame.width, dy: 0)
        thirdView.frame = viewFrame
        layoutLabelsAndImage(in: thirdView, pageFrame: viewFrame, portrait: portrait)
    }

    private func layoutFourthPage(portrait: Bool) {
        let viewFrame = thirdView.frame.offsetBy(dx: thirdView.frame.width, dy: 0)
        fourthView.frame = viewFrame
        layoutLabelsAndImage(in: fourthView, pageFrame: viewFrame, portrait: portrait)
    }

    private func layoutLabelsAndImage(in page: UIView, pageFrame: CGRect, portrait: Bool) {
        guard let titleLabel = page.viewWithTag(Tag.titleLabel) as? UILabel,
              let detailLabel = page.viewWithTag(Tag.detailLabel) as? UILabel,
              let imgView = page.viewWithTag(Tag.imageView) as? UIImageView else { return }

        let offsetY = titleOffsetY(portrait: portrait)
        let titleHeight = isPad ? kPadTitleHeight : kTitleHeight
        titleLabel.frame = CGRect(
            x: kPageHeight,
            y: offsetY,
            width: pageFrame.width - 2 * kPageHeight,
            height: titleHeight
        )
        detailLabel.frame = CGRect(
            x: kDetailHeight / 4,
            y: titleLabel.frame.maxY,
            width: pageFrame.width - kDetailHeight / 2,
            height: kDetailHeight
        )

        var length = min(pageFrame.width, pageFrame.height) - 4 * kPageHeight
        if isPad { length /= 2 }
        imgView.frame = CGRect(x: 0, y: 0, width: length, height: length)
        imgView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = view.bounds.width
        guard pageWidth > 0 else { return }
        let pageFraction = scrollView.contentOffset.x / pageWidth
        pageControl.currentPage = Int(round(pageFraction))
    }
}
