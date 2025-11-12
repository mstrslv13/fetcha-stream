import SwiftUI

struct LibraryPanel: View {
    @Binding var selectedItem: DownloadHistory.DownloadRecord?
    @State private var searchText = ""
    @State private var selectedCategory = "Recent"
    @StateObject private var downloadHistory = DownloadHistory.shared
    
    let categories = ["Recent", "Completed", "Failed", "All"]
    
    var filteredHistory: [DownloadHistory.DownloadRecord] {
        var items = Array(downloadHistory.history)
        
        // Apply category filter
        switch selectedCategory {
        case "Completed":
            break // All history items are completed
        case "Failed":
            items = [] // No failed items in history
        case "Recent":
            // Show last 50 items
            items = Array(items.prefix(50))
        default:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { record in
                record.title.localizedCaseInsensitiveContains(searchText) ||
                record.url.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: FreshUI.Spacing.md) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title2)
                        .foregroundColor(FreshUI.Colors.accentGreen)
                    
                    Text("Library")
                        .font(FreshUI.Typography.title)
                        .foregroundColor(FreshUI.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, FreshUI.Spacing.lg)
                .padding(.top, FreshUI.Spacing.lg)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FreshUI.Colors.textTertiary)
                    
                    TextField("Search downloads", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(FreshUI.Colors.textPrimary)
                }
                .padding(FreshUI.Spacing.xs)
                .background(FreshUI.Colors.surface)
                .cornerRadius(FreshUI.Radii.sm)
                .padding(.horizontal, FreshUI.Spacing.lg)
            }
            .padding(.bottom, FreshUI.Spacing.md)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FreshUI.Spacing.xs) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            title: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal, FreshUI.Spacing.lg)
            }
            .padding(.bottom, FreshUI.Spacing.md)
            
            Divider()
                .background(FreshUI.Colors.divider)
            
            // Content
            if filteredHistory.isEmpty {
                EmptyLibraryView(category: selectedCategory)
            } else {
                ScrollView {
                    LazyVStack(spacing: FreshUI.Spacing.xxs) {
                        ForEach(filteredHistory, id: \.id) { record in
                            LibraryItemCard(
                                record: record,
                                isSelected: selectedItem?.id == record.id,
                                action: { selectedItem = record }
                            )
                        }
                    }
                    .padding(.horizontal, FreshUI.Spacing.sm)
                    .padding(.vertical, FreshUI.Spacing.xs)
                }
                .scrollContentBackground(.hidden)
                .background(FreshUI.Colors.background)
            }
        }
        .freshSidebar()
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FreshUI.Typography.caption)
                .foregroundColor(isSelected ? .black : FreshUI.Colors.textPrimary)
                .padding(.horizontal, FreshUI.Spacing.sm)
                .padding(.vertical, FreshUI.Spacing.xxs)
                .background(
                    isSelected ? FreshUI.Colors.accentGreen : FreshUI.Colors.surface
                )
                .cornerRadius(FreshUI.Radii.full)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Item Card
struct LibraryItemCard: View {
    let record: DownloadHistory.DownloadRecord
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?
    
    var statusColor: Color {
        // History records are always completed
        return FreshUI.Colors.success
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FreshUI.Spacing.sm) {
                // Thumbnail
                ZStack {
                    if let thumbnailURL = record.thumbnail,
                       let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(FreshUI.Colors.surface)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(FreshUI.Colors.textTertiary)
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(FreshUI.Colors.surface)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                            )
                    }
                }
                .frame(width: FreshUI.Sizes.thumbnailSmall, height: FreshUI.Sizes.thumbnailSmall)
                .cornerRadius(FreshUI.Radii.xs)
                
                // Info
                VStack(alignment: .leading, spacing: FreshUI.Spacing.xxxs) {
                    Text(record.title)
                        .font(FreshUI.Typography.body)
                        .foregroundColor(FreshUI.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: FreshUI.Spacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(formatDate(record.timestamp))
                            .font(FreshUI.Typography.small)
                            .foregroundColor(FreshUI.Colors.textSecondary)
                        
                        if record.duration != nil {
                            Text("•")
                                .foregroundColor(FreshUI.Colors.textTertiary)
                            Text(formatDuration(Int(record.duration!)))
                                .font(FreshUI.Typography.small)
                                .foregroundColor(FreshUI.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(FreshUI.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: FreshUI.Radii.sm)
                    .fill(isSelected ? FreshUI.Colors.surfaceSelected :
                          (isHovered ? FreshUI.Colors.surfaceHover : Color.clear))
            )
            .onHover { hovering in
                withAnimation(FreshUI.Animation.fast) {
                    isHovered = hovering
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Empty State
struct EmptyLibraryView: View {
    let category: String
    
    var emptyMessage: String {
        switch category {
        case "Recent":
            return "No recent downloads"
        case "Completed":
            return "No completed downloads"
        case "Failed":
            return "No failed downloads"
        default:
            return "Your library is empty"
        }
    }
    
    var body: some View {
        VStack(spacing: FreshUI.Spacing.md) {
            Spacer()
            
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundColor(FreshUI.Colors.textTertiary)
            
            Text(emptyMessage)
                .font(FreshUI.Typography.headline)
                .foregroundColor(FreshUI.Colors.textSecondary)
            
            Text("Downloads will appear here")
                .font(FreshUI.Typography.caption)
                .foregroundColor(FreshUI.Colors.textTertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}