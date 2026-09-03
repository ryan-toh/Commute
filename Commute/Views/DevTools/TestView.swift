#if DEBUG
import SwiftUI
import UIKit

/// A small UIKit surface hosted inside SwiftUI for development experiments.
struct TestView: View {
    var body: some View {
        NavigationStack {
            UIKitTestController()
                .navigationTitle(Preferences.DevTools.uikitTestTitle)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - UIKit Controller
private struct UIKitTestController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitTestViewController {
        UIKitTestViewController()
    }

    func updateUIViewController(_ viewController: UIKitTestViewController, context: Context) {
        // SwiftUI has no input state to apply to this UIKit experiment yet.
    }
}

// MARK: UIKit Home View
private final class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemYellow
    }
}

// MARK: UIKit Upcoming View
private final class UpcomingViewControler: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGreen
    }
}

// MARK: - UIKit Search View
private final class SearchViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemPink
    }
}

// MARK: - UIKit Downloads View
private final class DownloadViewContorller: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemCyan
    }
}

// MARK: - UIKit View
private final class UIKitTestViewController: UITabBarController {

    /**
        ORDERING matters in this sequence
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemMint
        
        let vc1 = UINavigationController(rootViewController: HomeViewController())
        let vc2 = UINavigationController(rootViewController: UpcomingViewControler())
        let vc3 = UINavigationController(rootViewController: SearchViewController())
        let vc4 = UINavigationController(rootViewController: DownloadViewContorller())
        
        vc1.tabBarItem.image = UIImage(systemName: "house")
        vc2.tabBarItem.image = UIImage(systemName: "play.circle")
        vc3.tabBarItem.image = UIImage(systemName: "magnifyingglass")
        vc4.tabBarItem.image = UIImage(systemName:  "arrow.down.to.line")
        
        vc1.title = "Home"
        vc2.title = "Coming"
        vc3.title = "Search"
        vc4.title = "Downloads"
        
        tabBar.tintColor = .label
        
        setViewControllers([vc1, vc2, vc3, vc4], animated: true)
        
        /*
        // 1. create label
        let label = UILabel()
        
        // 2. tell UIKit what the label contains
        label.text = "Hello, world!"
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Add subview to the view
        view.addSubview(label)
        
        // 4. create constraints
        let centerX = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        
        // 5. add POSITIONING constraints to its PARENT container
        view.addConstraints([centerX, centerY])
        
        // 6. add SIZING constrants to its OWN container
         */
        
    }
}

#Preview {
    TestView()
}
#endif
