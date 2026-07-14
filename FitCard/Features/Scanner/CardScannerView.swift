import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct CardScannerView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = CardScannerViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var confirmRecognition: RecognitionResult?
    @State private var confirmMatchedExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                instructionsSection

                if viewModel.isProcessing {
                    ProgressView("Extracting text…")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let capturedImage = viewModel.capturedImage {
                    scanResultSection(image: capturedImage)
                } else {
                    captureSection
                }
            }
            .padding()
            .padding(.bottom, viewModel.capturedImage == nil ? 0 : 120)
        }
        .navigationTitle("Scan Card")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if viewModel.capturedImage != nil {
                scanActionBar
            }
        }
        .fullScreenCover(item: $confirmRecognition) { recognition in
            NavigationStack {
                ExerciseConfirmView(
                    recognitionResult: recognition,
                    existingExercise: confirmMatchedExercise,
                    onFinished: {
                        confirmRecognition = nil
                        confirmMatchedExercise = nil
                        viewModel.reset()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingScanner) {
            DocumentCameraView(
                onComplete: { images in
                    Task { await viewModel.handleCapturedImages(images) }
                },
                onCancel: {
                    viewModel.handleCancel()
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await viewModel.handleCapturedImages([image])
                selectedPhoto = nil
            }
        }
    }

    private var scanActionBar: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.prepareConfirmation(using: modelContext)
                    if let result = viewModel.pendingRecognition {
                        confirmMatchedExercise = viewModel.matchedExercise
                        confirmRecognition = result
                    }
                }
            } label: {
                Label("Continue to Save", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isProcessing || viewModel.scanResult == nil)

            Button(action: viewModel.reset) {
                Label("Scan Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var instructionsSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Scan an exercise card")
                .font(.title2.bold())

            Text("Position the card within the camera frame. OtterlyFit will capture the image and extract text using Vision.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var captureSection: some View {
        VStack(spacing: 12) {
            if viewModel.isDocumentScannerAvailable {
                Button(action: viewModel.startScan) {
                    Label("Scan with Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(
                    viewModel.isDocumentScannerAvailable ? "Choose from Photos" : "Choose Photo",
                    systemImage: "photo.on.rectangle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            sampleScanSection
        }
    }

    private var sampleScanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Simulator Testing")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Text("No photo needed — use a built-in sample card to test OCR and exercise matching.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(SampleScanKind.allCases) { kind in
                Button {
                    Task { await viewModel.loadSampleScan(kind) }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Try Sample: \(kind.rawValue)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(kind.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 8)
    }

    private func scanResultSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Captured Card")
                .font(.headline)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Extracted Text")
                    .font(.headline)

                if let text = viewModel.scanResult?.recognizedText, !text.isEmpty {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("No text detected. Try again with better lighting or a clearer photo.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Text("Use the Continue button below to review and save this exercise.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CardScannerView()
    }
    .modelContainer(ModelContainer.preview)
}
