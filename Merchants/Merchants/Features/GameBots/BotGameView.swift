import MerchantsGame
import SwiftUI

struct BotGameView: View {
    @State private var model = BotGameModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let state = model.state {
                    BotGameBoardView(state: state, winners: model.winners)

                    Text("Latest decision")
                        .font(.headline)
                    Text(model.message)
                        .textSelection(.enabled)

                    if state.ending.status != .finished {
                        Button(model.isRunning ? "Pause" : "Start") {
                            model.setRunning(!model.isRunning)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isStepping || model.isPreparing || model.error != nil)
                    } else if model.error == nil {
                        Button("New game") {
                            Task { await model.prepare() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isPreparing || model.isStepping)
                    }
                } else if model.isPreparing {
                    ProgressView("Preparing game")
                }

                if let error = model.error {
                    Text("The game stopped: \(error)")
                        .foregroundStyle(.red)
                    Button("Try a new game") {
                        Task { await model.prepare() }
                    }
                    .disabled(model.isPreparing || model.isStepping)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Bot game")
        .task {
            await model.prepare()
        }
        .task(id: model.isRunning) {
            await model.run()
        }
    }
}
