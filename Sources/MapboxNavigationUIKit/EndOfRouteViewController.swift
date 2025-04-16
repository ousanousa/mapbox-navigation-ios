import MapboxDirections
import MapboxNavigationCore
import UIKit

private enum ConstraintSpacing: CGFloat {
    case closer = 8.0
    case further = 65.0
}

private enum ContainerHeight: CGFloat {
    case normal = 200
    case commentShowing = 260
}

@_documentation(visibility: internal)
open class EndOfRouteContentView: UIView {}

@_documentation(visibility: internal)
open class EndOfRouteTitleLabel: StylableLabel {}

@_documentation(visibility: internal)
open class EndOfRouteStaticLabel: StylableLabel {}

@_documentation(visibility: internal)
open class EndOfRouteCommentView: StylableTextView {}

@_documentation(visibility: internal)
open class EndOfRouteButton: StylableButton {}

class EndOfRouteViewController: UIViewController {
    // MARK: IBOutlets

    @IBOutlet var labelContainer: UIView!
    @IBOutlet var staticYouHaveArrived: EndOfRouteStaticLabel!
    @IBOutlet var primary: UILabel!
    @IBOutlet var endNavigationButton: UIButton!
    @IBOutlet var stars: RatingControl!
    @IBOutlet var commentView: UITextView!
    @IBOutlet var commentViewContainer: UIView!
    @IBOutlet var showCommentView: NSLayoutConstraint!
    @IBOutlet var hideCommentView: NSLayoutConstraint!
    @IBOutlet var ratingCommentsSpacing: NSLayoutConstraint!

    // MARK: Properties

    var imagePlaceholderView: UIView!

    lazy var placeholder: String = "END_OF_ROUTE_TITLE".localizedString(
        value: "How can we improve?",
        comment: "Comment Placeholder Text"
    )

    typealias DismissHandler = (Int, String?) -> Void
    var dismissHandler: DismissHandler?
    var comment: String?
    var rating: Int = 0 {
        didSet {
            rating == 0 ? hideComments() : showComments()
        }
    }

    open var destination: Waypoint? {
        didSet {
            guard isViewLoaded else { return }
            updateInterface()
        }
    }

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Clear default subviews if added from Storyboard initially
        view.subviews.forEach { $0.removeFromSuperview() }

        // Setup the main content stack view
        setupContentStackView()

        clearInterface() // Should be called after setup if it affects outlets
        stars.didChangeRating = { [weak self] new in self?.rating = new }
        setPlaceholderText()
        styleCommentView()
        commentViewContainer.alpha = 0.0 // setting initial hidden state
        staticYouHaveArrived.text = "END_OF_ROUTE_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title used for arrival"
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateInterface()
        commentView.text = placeholder
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rating == 0 ? hideComments() : showComments()
    }

    // MARK: IBActions

    @IBAction
    func endNavigationPressed(_ sender: Any) {
        dismissView()
    }

    // MARK: Private Functions

    private func styleCommentView() {
        commentView.layer.cornerRadius = 6.0
        commentView.layer.borderColor = UIColor.lightGray.cgColor
        commentView.layer.borderWidth = 1.0
        commentView.textContainerInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    fileprivate func dismissView() {
        let dismissal: () -> Void = { self.dismissHandler?(self.rating, self.comment) }
        guard commentView.isFirstResponder else { return _ = dismissal() }
        commentView.resignFirstResponder()
        let fireTime = DispatchTime.now() + 0.3 // Not ideal, but works for now
        DispatchQueue.main.asyncAfter(deadline: fireTime, execute: dismissal)
    }

    private func showComments(animated: Bool = true) {
        showCommentView.isActive = true
        hideCommentView.isActive = false
        ratingCommentsSpacing.constant = ConstraintSpacing.closer.rawValue

        let animate = {
            self.view.layoutIfNeeded()
            self.commentViewContainer.alpha = 1.0
            self.labelContainer.alpha = 0.0
        }

        let completion: (Bool) -> Void = { _ in self.labelContainer.isHidden = true }
        let noAnimate = { animate(); completion(true) }
        animated ? UIView.animate(withDuration: 0.3, animations: animate, completion: nil) : noAnimate()
    }

    private func hideComments(animated: Bool = true) {
        labelContainer.isHidden = false
        showCommentView.isActive = false
        hideCommentView.isActive = true
        ratingCommentsSpacing.constant = ConstraintSpacing.further.rawValue

        let animate = {
            self.view.layoutIfNeeded()
            self.commentViewContainer.alpha = 0.0
            self.labelContainer.alpha = 1.0
        }

        let completion: (Bool) -> Void = { _ in self.commentViewContainer.isHidden = true }
        let noAnimation = { animate(); completion(true) }
        animated ? UIView.animate(withDuration: 0.3, animations: animate, completion: nil) : noAnimation()
    }

    private func updateInterface() {
        guard let name = destination?.name?.nonEmptyString else { return styleForUnnamedDestination() }
        staticYouHaveArrived.isHidden = false
        primary.text = name
    }

    private func clearInterface() {
        primary.text = nil
        stars.rating = 0
    }

    private func styleForUnnamedDestination() {
        staticYouHaveArrived.isHidden = true
        primary.text = "END_OF_ROUTE_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title used for arrival"
        )
    }

    private func setPlaceholderText() {
        commentView.text = placeholder
    }

    private func setupContentStackView() {
        // Créer un container principal avec padding
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Contraintes pour le container
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])

        // Stack view principal
        let mainStack = UIStackView()
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        containerView.addSubview(mainStack)

        // Contraintes pour le stack principal avec padding horizontal
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24)
        ])

        guard let labelContainer = self.labelContainer,
              let stars = self.stars,
              let commentViewContainer = self.commentViewContainer,
              let endNavigationButton = self.endNavigationButton else {
            return
        }

        // Configurer le titre
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        staticYouHaveArrived.font = .systemFont(ofSize: 28, weight: .bold)
        staticYouHaveArrived.textAlignment = .center
        
        // Configurer les étoiles
        stars.translatesAutoresizingMaskIntoConstraints = false
        
        // Créer un conteneur pour les étoiles pour les centrer
        let starsContainer = UIView()
        starsContainer.translatesAutoresizingMaskIntoConstraints = false
        starsContainer.addSubview(stars)
        
        // Centrer les étoiles dans leur conteneur
        NSLayoutConstraint.activate([
            stars.centerXAnchor.constraint(equalTo: starsContainer.centerXAnchor),
            stars.centerYAnchor.constraint(equalTo: starsContainer.centerYAnchor),
            stars.topAnchor.constraint(equalTo: starsContainer.topAnchor),
            stars.bottomAnchor.constraint(equalTo: starsContainer.bottomAnchor)
        ])
        
        // Configurer la zone d'image
        setupImagePlaceholderView()
        
        // Configurer le bouton
        endNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Ajouter les éléments au stack
        mainStack.addArrangedSubview(labelContainer)
        mainStack.addArrangedSubview(starsContainer)
        mainStack.addArrangedSubview(imagePlaceholderView)
        mainStack.addArrangedSubview(endNavigationButton)
        
        // Configurer les contraintes de largeur
        [labelContainer, starsContainer, imagePlaceholderView, endNavigationButton].forEach { view in
            view.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        }
        
        // Ajouter un spacer en bas
        let spacerView = UIView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(spacerView)
        
        // Contrainte de hauteur minimale pour le spacer
        spacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        
        // Configurer les priorités
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // S'assurer que le stack principal reste en haut
        mainStack.setContentHuggingPriority(.required, for: .vertical)
        mainStack.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func setupImagePlaceholderView() {
        imagePlaceholderView = UIView()
        imagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        imagePlaceholderView.backgroundColor = .systemGray5
        imagePlaceholderView.layer.cornerRadius = 8
        
        // Définir une hauteur fixe pour la zone d'image
        imagePlaceholderView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func setupSpacerView(below topView: UIView) { // Pass the view above the spacer
        let spacerView = UIView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.backgroundColor = .clear // Spacer is invisible
        view.addSubview(spacerView)

        // Constraints for the spacer view
        let topConstraint = spacerView.topAnchor.constraint(equalTo: topView.bottomAnchor) // Below the passed topView (contentStackView)
        let bottomConstraint = spacerView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // Pinned to the container bottom

        // Lower the priority of the bottom constraint. This allows the spacer to shrink/grow
        // while the contentStackView remains attached to the top.
        bottomConstraint.priority = .defaultHigh // Higher than defaultLow, but less than required

        NSLayoutConstraint.activate([
            topConstraint,
            spacerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spacerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            // Height constraint that allows the spacer to fill remaining space
            spacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }
}

// MARK: UITextViewDelegate

extension EndOfRouteViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.count == 1, text.rangeOfCharacter(from: CharacterSet.newlines) != nil else { return true }
        textView.resignFirstResponder()
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        comment = textView.text // Bind data model
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = nil
            textView.alpha = 1.0
        }
        textView.becomeFirstResponder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text?.isEmpty ?? true) == true {
            textView.text = placeholder
            textView.alpha = 0.9
        }
    }
}
