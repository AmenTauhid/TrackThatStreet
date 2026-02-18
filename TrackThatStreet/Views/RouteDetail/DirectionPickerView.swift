import SwiftUI

struct DirectionPickerView: View {
    let directions: [Direction]
    @Binding var selectedTag: String?

    var body: some View {
        if directions.count > 1 {
            Picker("Direction", selection: $selectedTag) {
                ForEach(directions) { direction in
                    Text(direction.title)
                        .tag(Optional(direction.tag))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}
