import SwiftUI

struct ThemePreferencesView: View {
    @ObservedObject var viewModel: ThemePreferencesViewModel

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("GÖRÜNÜM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.AppPrimary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tema Hakkında")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Uygulamanın görünümünü Sistem, Açık veya Koyu olarak ayarlayabilirsin. Değişiklikler anında uygulanır.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))

                    VStack(spacing: 0) {
                        themeRow(option: .system)
                        Divider().padding(.leading)
                        themeRow(option: .light)
                        Divider().padding(.leading)
                        themeRow(option: .dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Tema")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)

            if viewModel.isSaving {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView("Kaydediliyor...")
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
        }
        .tint(.AppPrimary)
    }

    @ViewBuilder
    private func themeRow(option: ThemeOption) -> some View {
        Button {
            viewModel.selected = option
            viewModel.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.icon).foregroundStyle(.AppPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .fontWeight(.semibold)
                }
                Spacer()
                Image(systemName: viewModel.selected == option ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(viewModel.selected == option ? .AppPrimary : .secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ThemePreferencesView(viewModel: ThemePreferencesViewModel()) }
}
