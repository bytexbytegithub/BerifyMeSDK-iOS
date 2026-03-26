import UIKit

/// Searchable country / calling-code picker (sheet).
final class PhoneCountryPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    private let onSelect: (PhoneCountryOption) -> Void
    private let allOptions: [PhoneCountryOption]
    private var filteredOptions: [PhoneCountryOption]
    private let selectedIso2Upper: String

    private let tableView = UITableView(frame: .zero, style: .plain)

    init(options: [PhoneCountryOption], selectedIso2: String, onSelect: @escaping (PhoneCountryOption) -> Void) {
        self.allOptions = options
        self.filteredOptions = options
        self.selectedIso2Upper = selectedIso2.uppercased()
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        title = "Country / region"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let raw = searchController.searchBar.text ?? ""
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let qDigits = q.filter { $0.isNumber }
        if q.isEmpty {
            filteredOptions = allOptions
        } else {
            filteredOptions = allOptions.filter { opt in
                opt.localizedRegionName.lowercased().contains(q)
                    || opt.iso2.lowercased().contains(q)
                    || (!qDigits.isEmpty && opt.callingCode.contains(qDigits))
            }
        }
        tableView.reloadData()
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let opt = filteredOptions[indexPath.row]
        cell.textLabel?.text = opt.displayTitle(showFlag: true)
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.accessoryType = opt.iso2 == selectedIso2Upper ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let opt = filteredOptions[indexPath.row]
        dismiss(animated: true) {
            self.onSelect(opt)
        }
    }
}
