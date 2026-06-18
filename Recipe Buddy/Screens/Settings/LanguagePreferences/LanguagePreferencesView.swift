import SwiftUI

struct LanguagePreferencesView: View {
    @ObservedObject var viewModel: LanguagePreferencesViewModel

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("DİL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "globe")
                            .foregroundStyle(.AppPrimary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dil Hakkında")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Uygulama dilini sistem dilinden bağımsız olarak değiştirebilirsin. Yeni diller eklemek için ilgili çeviri dosyalarının tamamlanması gerekir.")
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
                        ForEach(LanguageOption.allCases) { option in
                            languageRow(option: option)

                            if option != LanguageOption.allCases.last {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                }
                .padding()
            }
            .navigationTitle("Dil")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
        }
        .tint(.AppPrimary)
    }

    private func languageRow(option: LanguageOption) -> some View {
        Button {
            viewModel.selected = option
            viewModel.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .foregroundStyle(.AppPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(option.title))
                        .fontWeight(.semibold)

                    Text(LocalizedStringKey(option.subtitle))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    NavigationStack {
        LanguagePreferencesView(viewModel: LanguagePreferencesViewModel())
    }
}

