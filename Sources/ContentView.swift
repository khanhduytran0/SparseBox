import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sharedModel: SharedModel
    var body: some View {
        TabView(selection: $sharedModel.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(TabIdentifier.home)
            NavigationStack { AppListView() }
                .tabItem {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Apps")
                }
                .tag(TabIdentifier.apps)
            NavigationStack { ProcessListView() }
                .tabItem {
                    Image(systemName: "waveform.path.ecg.magnifyingglass")
                    Text("Processes")
                }
                .tag(TabIdentifier.afc)
            MobileGestaltView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("MobileGestalt")
                }
                .tag(TabIdentifier.mobileGestalt)
            LogView()
                .tabItem {
                    Image(systemName: "apple.terminal")
                    Text("Log")
                }
                .tag(TabIdentifier.log)
        }
    }
}

#Preview {
    Text("Preview")
}
