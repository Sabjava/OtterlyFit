import SwiftUI

struct HomeView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Image("OtterlyFit2")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -geometry.size.height * 0.07)
                    .clipped()
                    .ignoresSafeArea()

                OtterlyFitLogoText(text: AppConstants.appName)
                    .padding(.top, geometry.size.height * 0.03)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Spacer()
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, max(8, 52 - geometry.size.height * 0.07))

                    Spacer()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
