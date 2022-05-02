import SwiftUI

struct SheetPresentationModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let detents: [UISheetPresentationController.Detent]
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        ZStack {
            Sheet(isPresented: $isPresented, onDismiss: onDismiss, detents: detents, content: {
                sheetContent()
            })

            content
        }
    }
}

extension View {
    func sheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        detents: [UISheetPresentationController.Detent],
        content: @escaping () -> SheetContent
    ) -> some View {
        modifier(SheetPresentationModifier(isPresented: isPresented, onDismiss: onDismiss, detents: detents, sheetContent: content))
    }
}
