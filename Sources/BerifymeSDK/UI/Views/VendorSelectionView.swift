import UIKit

/// Vendor selection view
class VendorSelectionView: UIView {
    private struct VendorItem {
        let key: String
        let title: String
        let subtitle: String
        let vendor: String
        let imageURL: String // Align RN SDK: add icon URL
    }
    
    private let titleStack: UIStackView
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel
    private let stepIconImageView: UIImageView
    private let recommendationStack: UIStackView
    private let recommendationTitleLabel: UILabel
    private let recommendationIconView: UIImageView
    private let recommendationCountryLabel: UILabel
    
    private let vendorsContainerStack: UIStackView
    private let showMoreButton: UIButton
    private var showMore: Bool = false {
        didSet { rebuildVendors() }
    }
    
    private let user: User
    private let onSelectVendor: (String) -> Void
    
    // Original vendor list (unsorted)
    private let allVendors: [VendorItem] = [
        VendorItem(
            key: "authid",
            title: "Berify.me",
            subtitle: "avg. 26s completion",
            vendor: "authid",
            imageURL: "https://idv.berify.me/little-berify.png"
        ),
        VendorItem(
            key: "clear",
            title: "CLEAR",
            subtitle: "avg. 60s completion",
            vendor: "clear",
            imageURL: "https://idv.berify.me/clear.png"
        ),
        VendorItem(
            key: "incode",
            title: "Incode",
            subtitle: "avg. 30s completion",
            vendor: "incode",
            imageURL: "https://idv.berify.me/incode.png"
        ),
    ]
    
    // Vendor list sorted by API order
    private var orderedVendors: [VendorItem] = []
    
    // Country name (for display)
    private var countryName: String = ""
    
    init(
        user: User,
        onSelectVendor: @escaping (String) -> Void
    ) {
        self.user = user
        self.onSelectVendor = onSelectVendor
        
        titleStack = UIStackView()
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        stepIconImageView = UIImageView()
        recommendationStack = UIStackView()
        recommendationTitleLabel = UILabel()
        recommendationIconView = UIImageView()
        recommendationCountryLabel = UILabel()
        
        vendorsContainerStack = UIStackView()
        showMoreButton = UIButton(type: .system)
        
        super.init(frame: .zero)
        setupUI()
        initializeUserCountryAndOrder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // Title area (align RN SDK: title and step icon)
        titleStack.axis = .horizontal
        titleStack.distribution = .equalSpacing
        titleStack.alignment = .center
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleStack)
        
        let titleContainer = UIStackView()
        titleContainer.axis = .vertical
        titleContainer.spacing = 8
        
        titleLabel.text = "Choose verification provider"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textAlignment = .left
        
        descriptionLabel.text = "Next: Upload ID and Take Selfie"
        descriptionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        descriptionLabel.textColor = UIColor(white: 0.41, alpha: 1.0)
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(descriptionLabel)
        titleStack.addArrangedSubview(titleContainer)
        
        // Step icon (align RN SDK: circlestep1.png)
        if let imageURL = URL(string: "https://idv.berify.me/circlestep1.png") {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.stepIconImageView.image = image
                }
            }.resume()
        }
        stepIconImageView.contentMode = .scaleAspectFit
        stepIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepIconImageView.widthAnchor.constraint(equalToConstant: 70),
            stepIconImageView.heightAnchor.constraint(equalToConstant: 70)
        ])
        titleStack.addArrangedSubview(stepIconImageView)
        
        // Recommended for row
        recommendationStack.axis = .horizontal
        recommendationStack.spacing = 6
        recommendationStack.alignment = .center
        recommendationStack.translatesAutoresizingMaskIntoConstraints = false
        
        recommendationTitleLabel.text = "Recommended for"
        recommendationTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        
        // Align RN SDK: use location.png
        if let imageURL = URL(string: "https://staging.berify.me/location.png") {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.recommendationIconView.image = image
                }
            }.resume()
        }
        recommendationIconView.contentMode = .scaleAspectFit
        recommendationIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recommendationIconView.widthAnchor.constraint(equalToConstant: 14),
            recommendationIconView.heightAnchor.constraint(equalToConstant: 14),
        ])
        
        // Initial display; updated from API result later
        recommendationCountryLabel.text = countryName.isEmpty ? "Loading..." : countryName
        recommendationCountryLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        recommendationStack.addArrangedSubview(recommendationTitleLabel)
        recommendationStack.addArrangedSubview(recommendationIconView)
        recommendationStack.addArrangedSubview(recommendationCountryLabel)
        addSubview(recommendationStack)
        
        // Vendors grid container (2 columns via nested horizontal stacks)
        vendorsContainerStack.axis = .vertical
        vendorsContainerStack.spacing = 16
        vendorsContainerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vendorsContainerStack)
        
        // Show more button
        showMoreButton.setTitle("Show More", for: .normal)
        showMoreButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        showMoreButton.setTitleColor(UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1.0), for: .normal)
        showMoreButton.addTarget(self, action: #selector(toggleShowMore), for: .touchUpInside)
        showMoreButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(showMoreButton)
        
        rebuildVendors()
        
        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            recommendationStack.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 16),
            recommendationStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            recommendationStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            vendorsContainerStack.topAnchor.constraint(equalTo: recommendationStack.bottomAnchor, constant: 16),
            vendorsContainerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            vendorsContainerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            showMoreButton.topAnchor.constraint(equalTo: vendorsContainerStack.bottomAnchor, constant: 12),
            showMoreButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            showMoreButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }
    
    /// Initialize user country and vendor order (align RN SDK)
    private func initializeUserCountryAndOrder() {
        guard let phoneNumber = user.phoneNumber else {
            // If no phone number, use device region as fallback
            let regionCode = Locale.current.regionCode ?? "US"
            countryName = Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
            orderedVendors = allVendors
            updateCountryLabel()
            rebuildVendors()
            return
        }
        
        // Parse country code from phone number
        let countryCode = CountryCodeHelper.getCountryCodeFromPhoneNumber("+\(phoneNumber)") ?? "US"
        countryName = CountryCodeHelper.getCountryNameByCode(countryCode)
        updateCountryLabel()
        
        // Call API to get vendor order
        Task {
            do {
                guard let toolsAPI = BerifymeSDK.shared.tools else {
                    // API not initialized, use default order
                    await MainActor.run {
                        orderedVendors = allVendors
                        rebuildVendors()
                    }
                    return
                }
                
                let response = try await toolsAPI.getOrderByCountry(countryCode: countryCode)
                
                await MainActor.run {
                    if let order = response.order, !order.isEmpty {
                        // Reorder vendors by API response
                        orderedVendors = order.compactMap { key in
                            allVendors.first { $0.key == key }
                        }
                        // Add vendors not in API response (original order)
                        let orderedKeys = Set(order)
                        let remainingVendors = allVendors.filter { !orderedKeys.contains($0.key) }
                        orderedVendors.append(contentsOf: remainingVendors)
                    } else {
                        // If API returns no order or error, use default order
                        orderedVendors = allVendors
                    }
                    rebuildVendors()
                }
            } catch {
                // On error use default order
                await MainActor.run {
                    orderedVendors = allVendors
                    rebuildVendors()
                }
            }
        }
    }
    
    private func updateCountryLabel() {
        recommendationCountryLabel.text = countryName
    }
    
    private func rebuildVendors() {
        vendorsContainerStack.arrangedSubviews.forEach { view in
            vendorsContainerStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        // Use sorted vendor list
        let vendorsToUse = orderedVendors.isEmpty ? allVendors : orderedVendors
        let visibleVendors = showMore ? vendorsToUse : Array(vendorsToUse.prefix(2))
        let rows: [[VendorItem]] = stride(from: 0, to: visibleVendors.count, by: 2).map {
            Array(visibleVendors[$0..<min($0 + 2, visibleVendors.count)])
        }
        
        for rowItems in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 16
            rowStack.distribution = .fillEqually
            
            for item in rowItems {
                let button = makeVendorCard(item: item)
                rowStack.addArrangedSubview(button)
            }
            
            if rowItems.count == 1 {
                rowStack.addArrangedSubview(UIView()) // Fill right slot
            }
            
            vendorsContainerStack.addArrangedSubview(rowStack)
        }
        
        // Use declared vendorsToUse variable
        if vendorsToUse.count > 2 {
            showMoreButton.isHidden = false
            showMoreButton.setTitle(showMore ? "Show Less" : "Show More", for: .normal)
        } else {
            showMoreButton.isHidden = true
        }
    }
    
    private func makeVendorCard(item: VendorItem) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.layer.cornerRadius = 24
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.accessibilityIdentifier = item.vendor
        button.addTarget(self, action: #selector(vendorButtonTapped(_:)), for: .touchUpInside)
        
        // Create vertical StackView for icon and text (align RN SDK)
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = 8
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Vendor icon (align RN SDK)
        let iconImageView = UIImageView()
        if let imageURL = URL(string: item.imageURL) {
            URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    iconImageView.image = image
                }
            }.resume()
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36)
        ])
        cardStack.addArrangedSubview(iconImageView)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        cardStack.addArrangedSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 0.41, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        cardStack.addArrangedSubview(subtitleLabel)
        
        button.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            cardStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            cardStack.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 8),
            cardStack.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -8),
            
            button.heightAnchor.constraint(equalToConstant: 140)
        ])
        
        return button
    }
    
    @objc private func vendorButtonTapped(_ sender: UIButton) {
        let vendor = sender.accessibilityIdentifier ?? ""
        onSelectVendor(vendor)
    }
    
    @objc private func toggleShowMore() {
        showMore.toggle()
    }
}
