import SwiftData
import SwiftUI

/// The main dashboard view showing active regions (Morning, Afternoon, Evening) as summary cards.
///
/// Displays today's task overview with region cards, daily progress,
/// and navigation to individual RegionFocusViews. Triggers day rollover
/// on appearance. Backlog is now a separate tab and no longer shown here.
struct TodayView: View {
    @State var viewModel: TodayViewModel
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.standard) {
                dailyProgressHeader

                rolloverBanner

                regionCards

                if viewModel.totalActiveTaskCount == 0 && !viewModel.isLoading {
                    emptyDayMessage
                }
            }
            .padding(.horizontal, Theme.Spacing.standard)
            .padding(.bottom, Theme.Spacing.large)
        }
        .background(Theme.Colors.groupedBackground)
        .navigationTitle("Today")
        .task {
            viewModel.performDayRollover()
        }
        .refreshable {
            viewModel.loadTodaysTasks()
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK") { viewModel.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Subviews

    private var dailyProgressHeader: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                Text(formattedDate)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                if viewModel.totalActiveTaskCount > 0 {
                    Text("\(viewModel.completedActiveTaskCount)/\(viewModel.totalActiveTaskCount) done")
                        .font(Theme.Typography.captionMonospaced)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            if viewModel.totalActiveTaskCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.Colors.textTertiary.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                viewModel.dailyCompletionFraction >= 1.0
                                    ? Theme.Colors.success
                                    : Theme.Colors.accent
                            )
                            .frame(
                                width: geometry.size.width * viewModel.dailyCompletionFraction,
                                height: 6
                            )
                            .animation(.easeInOut(duration: 0.3), value: viewModel.dailyCompletionFraction)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.top, Theme.Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(formattedDate). \(viewModel.completedActiveTaskCount) of \(viewModel.totalActiveTaskCount) tasks completed."
        )
    }

    @ViewBuilder
    private var rolloverBanner: some View {
        if let count = viewModel.rolledOverCount {
            HStack {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(Theme.Colors.warning)

                Text("\(count) task\(count == 1 ? "" : "s") moved to Backlog")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Button {
                    viewModel.dismissRolloverBanner()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.medium)
            .background(
                Theme.Colors.warning.opacity(0.1),
                in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
            )
        }
    }

    private var regionCards: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ForEach(Region.activeRegions, id: \.self) { region in
                RegionCard(
                    region: region,
                    tasks: viewModel.tasks(for: region),
                    onTap: {
                        coordinator.navigate(to: .regionFocus(region))
                    }
                )
            }
        }
    }

    private var emptyDayMessage: some View {
        EmptyStateView(
            systemImageName: "sparkles",
            title: "No tasks planned for today",
            subtitle: "Tap a region to start planning your day"
        )
    }

    // MARK: - Helpers

    private var formattedDate: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewData.container
    let taskService = TaskService(modelContext: container.mainContext)
    NavigationStack {
        TodayView(viewModel: TodayViewModel(taskService: taskService))
    }
    .environment(AppCoordinator())
    .modelContainer(container)
}
