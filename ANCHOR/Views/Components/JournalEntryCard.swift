//
//  JournalEntryCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import Combine

struct JournalEntryCard: View {
    // MARK: - Core Properties
    let entry: JournalEntryModel
    
    // MARK: - Customization Properties
    let style: CardStyle
    let size: CardSize
    let showMoodIcon: Bool
    let showChevron: Bool
    let showTags: Bool
    let showTimestamp: Bool
    let showWordCount: Bool
    let showAttachmentIndicator: Bool
    let maxTagsVisible: Int
    let titleLineLimit: Int
    let bodyLineLimit: Int
    let previewCharacterLimit: Int
    let dateFormat: DateDisplayFormat
    let interactionStyle: InteractionStyle
    let customPadding: EdgeInsets?
    let customCornerRadius: CGFloat?
    let customShadow: ANCHORDesign.Shadow?
    let customBackground: AnyView?
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let contextMenuActions: [ContextMenuAction]
    
    // MARK: - Animation Properties
    let animateOnAppear: Bool
    let hoverEffect: Bool
    let scaleOnPress: Bool
    let hapticFeedback: Bool
    
    // MARK: - Feature Flags
    let enableAnalytics: Bool
    let enableCache: Bool
    let enableKeyboardNavigation: Bool
    let enableAdvancedGestures: Bool
    let enableParticleEffects: Bool
    
    // MARK: - State Management
    let loadingStateBinding: Binding<ComponentLoadingState>?
    
    // MARK: - Advanced Gesture Handlers
    let onDoubleTap: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let onSwipeUp: (() -> Void)?
    let onSwipeDown: (() -> Void)?
    
    // MARK: - Accessibility Properties
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let accessibilityValue: String?
    let accessibilityActions: [AccessibilityAction]?
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var isPressed = false
    @State private var isHovered = false
    @StateObject private var loadingState = ComponentLoadingState()
    @State private var showParticleEffect = false
    @State private var cachedImage: UIImage?
    @State private var showFullText = false
    
    // MARK: - Initializers
    init(
        entry: JournalEntryModel,
        style: CardStyle = .standard,
        size: CardSize = .medium,
        showMoodIcon: Bool = true,
        showChevron: Bool = true,
        showTags: Bool = true,
        showTimestamp: Bool = true,
        showWordCount: Bool = false,
        showAttachmentIndicator: Bool = false,
        maxTagsVisible: Int = 4,
        titleLineLimit: Int = 2,
        bodyLineLimit: Int = 2,
        previewCharacterLimit: Int = 80,
        dateFormat: DateDisplayFormat = .dateAndTime,
        interactionStyle: InteractionStyle = .standard,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customShadow: ANCHORDesign.Shadow? = nil,
        customBackground: AnyView? = nil,
        animateOnAppear: Bool = false,
        hoverEffect: Bool = true,
        scaleOnPress: Bool = true,
        hapticFeedback: Bool = true,
        enableAnalytics: Bool = false,
        enableCache: Bool = false,
        enableKeyboardNavigation: Bool = false,
        enableAdvancedGestures: Bool = false,
        enableParticleEffects: Bool = false,
        loadingStateBinding: Binding<ComponentLoadingState>? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        accessibilityActions: [AccessibilityAction]? = nil,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        onSwipeDown: (() -> Void)? = nil,
        contextMenuActions: [ContextMenuAction] = []
    ) {
        self.entry = entry
        self.style = style
        self.size = size
        self.showMoodIcon = showMoodIcon
        self.showChevron = showChevron
        self.showTags = showTags
        self.showTimestamp = showTimestamp
        self.showWordCount = showWordCount
        self.showAttachmentIndicator = showAttachmentIndicator
        self.maxTagsVisible = maxTagsVisible
        self.titleLineLimit = titleLineLimit
        self.bodyLineLimit = bodyLineLimit
        self.previewCharacterLimit = previewCharacterLimit
        self.dateFormat = dateFormat
        self.interactionStyle = interactionStyle
        self.customPadding = customPadding
        self.customCornerRadius = customCornerRadius
        self.customShadow = customShadow
        self.customBackground = customBackground
        self.animateOnAppear = animateOnAppear
        self.hoverEffect = hoverEffect
        self.scaleOnPress = scaleOnPress
        self.hapticFeedback = hapticFeedback
        self.enableAnalytics = enableAnalytics
        self.enableCache = enableCache
        self.enableKeyboardNavigation = enableKeyboardNavigation
        self.enableAdvancedGestures = enableAdvancedGestures
        self.enableParticleEffects = enableParticleEffects
        self.loadingStateBinding = loadingStateBinding
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.accessibilityActions = accessibilityActions
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.onDoubleTap = onDoubleTap
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.contextMenuActions = contextMenuActions
    }
    
    // MARK: - Computed Properties
    private var moodColor: Color {
        switch entry.sentiment {
        case 2: return ANCHORDesign.Colors.moodHappy
        case 1: return ANCHORDesign.Colors.moodHappy
        case 0: return ANCHORDesign.Colors.moodNeutral
        case -1: return ANCHORDesign.Colors.moodSad
        case -2: return ANCHORDesign.Colors.moodAngry
        default: return ANCHORDesign.Colors.moodNeutral
        }
    }
    
    private var moodIcon: ANCHORMoodIcon.MoodType {
        switch entry.sentiment {
        case 2: return .veryHappy
        case 1: return .happy
        case 0: return .neutral
        case -1: return .sad
        case -2: return .verySad
        default: return .neutral
        }
    }
    
    private var previewText: String {
        if let title = entry.title, !title.isEmpty {
            return title
        } else {
            let preview = entry.body.prefix(previewCharacterLimit).trimmingCharacters(in: .whitespacesAndNewlines)
            return preview + (entry.body.count > previewCharacterLimit ? "..." : "")
        }
    }
    
    private var wordCount: Int {
        entry.body.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private var cardPadding: EdgeInsets {
        customPadding ?? EdgeInsets(
            top: size.padding,
            leading: size.padding,
            bottom: size.padding,
            trailing: size.padding
        )
    }
    
    private var cardCornerRadius: CGFloat {
        customCornerRadius ?? size.cornerRadius
    }
    
    private var cardShadow: ANCHORDesign.Shadow {
        customShadow ?? style.shadow
    }
    
    private var moodIconSize: CGFloat {
        switch size {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        }
    }
    
    var body: some View {
        Group {
            if loadingStateBinding?.wrappedValue.isLoading == true {
                loadingView
            } else if let error = loadingStateBinding?.wrappedValue.error {
                errorView(error)
            } else {
                mainCardView
            }
        }
        .onAppear {
            setupComponent()
        }
        .onDisappear {
            cleanupComponent()
        }
    }
    
    @ViewBuilder
    private var mainCardView: some View {
        Group {
            if enableAdvancedGestures {
                cardContent
                    .advancedGestures(
                        onTap: handleTap,
                        onDoubleTap: onDoubleTap,
                        onLongPress: handleLongPress,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight,
                        onSwipeUp: onSwipeUp,
                        onSwipeDown: onSwipeDown
                    )
            } else if let onTap = onTap {
                Button(action: handleTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .scaleEffect(getScaleEffect())
        .opacity(hasAppeared || !animateOnAppear ? 1.0 : 0.0)
        .animation(SpringAnimation.bouncy, value: isPressed)
        .animation(SpringAnimation.gentle, value: hasAppeared)
        .animation(SpringAnimation.smooth, value: isHovered)
        .onHover { hovering in
            if hoverEffect {
                isHovered = hovering
            }
        }
        .modifier(accessibilityModifier)
        .modifier(keyboardNavigationModifier)
        .contextMenu {
            if !contextMenuActions.isEmpty {
                contextMenuView
            }
        }
        .overlay {
            if enableParticleEffects && showParticleEffect {
                ParticleEffect(particleCount: 10, colors: [moodColor, moodColor.opacity(0.7)])
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Card Content
    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: size.contentSpacing) {
            // Header Section
            if showMoodIcon || showTimestamp || showChevron || showWordCount || showAttachmentIndicator {
                headerSection
            }
            
            // Content Section
            contentSection
            
            // Tags Section
            if showTags && !entry.tags.isEmpty {
                tagsSection
            }
            
            // Footer Section (if needed)
            if style == .detailed {
                footerSection
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: ANCHORDesign.Spacing.sm) {
            // Mood Icon
            if showMoodIcon {
                ANCHORMoodIcon(mood: moodIcon, size: moodIconSize)
                    .animation(.spring(response: 0.3), value: moodIcon)
            }
            
            // Timestamp and metadata
            if showTimestamp {
                VStack(alignment: .leading, spacing: 2) {
                    switch dateFormat {
                    case .dateOnly:
                        Text(entry.date, style: .date)
                            .anchorTextStyle(size.dateStyle)
                    case .timeOnly:
                        Text(entry.date, style: .time)
                            .anchorTextStyle(size.dateStyle)
                    case .dateAndTime:
                        Text(entry.date, style: .date)
                            .anchorTextStyle(size.dateStyle)
                        Text(entry.date, style: .time)
                            .anchorTextStyle(size.timeStyle)
                    case .relative:
                        Text(entry.date, style: .relative(presentation: .named))
                            .anchorTextStyle(size.dateStyle)
                    }
                }
            }
            
            Spacer()
            
            // Metadata indicators
            HStack(spacing: ANCHORDesign.Spacing.xs) {
                if showWordCount {
                    HStack(spacing: 2) {
                        Image(systemName: "textformat.abc")
                            .font(.caption2)
                        Text("\(wordCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(ANCHORDesign.Colors.textTertiary)
                }
                
                if showAttachmentIndicator && !entry.tags.isEmpty { // Using tags as proxy for attachments
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(ANCHORDesign.Colors.accent)
                }
                
                if showChevron {
                    Image(systemName: interactionStyle.chevronIcon)
                        .font(.caption)
                        .foregroundColor(ANCHORDesign.Colors.textTertiary)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: size.contentSpacing) {
            // Title/Preview Text
            Text(previewText)
                .anchorTextStyle(size.titleStyle)
                .lineLimit(titleLineLimit)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Body preview (if different from title)
            if let title = entry.title, !title.isEmpty, bodyLineLimit > 0 {
                Text(entry.body)
                    .anchorTextStyle(size.bodyStyle)
                    .lineLimit(bodyLineLimit)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ANCHORDesign.Spacing.xs) {
                ForEach(entry.tags.prefix(maxTagsVisible), id: \.self) { tag in
                    TagView(
                        text: tag,
                        style: style.tagStyle,
                        size: size.tagSize
                    )
                }
                
                if entry.tags.count > maxTagsVisible {
                    Text("+\(entry.tags.count - maxTagsVisible)")
                        .font(.system(size: size.tagSize.fontSize, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ANCHORDesign.Colors.textTertiary.opacity(0.1))
                        .foregroundColor(ANCHORDesign.Colors.textTertiary)
                        .cornerRadius(ANCHORDesign.CornerRadius.small)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        if style == .detailed {
            HStack {
                // Reading time estimate
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(max(1, wordCount / 200)) min read")
                        .font(.caption2)
                }
                .foregroundColor(ANCHORDesign.Colors.textTertiary)
                
                Spacer()
                
                // Sentiment indicator
                if entry.sentiment != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: entry.sentiment > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(entry.sentiment > 0 ? ANCHORDesign.Colors.success : ANCHORDesign.Colors.error)
                        
                        Text(entry.sentiment > 0 ? "Positive" : "Negative")
                            .font(.caption2)
                            .foregroundColor(ANCHORDesign.Colors.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Loading and Error Views
    @ViewBuilder
    private var loadingView: some View {
        ShimmeringView(
            config: ShimmeringView.Configuration(gradient: Gradient(colors: [ANCHORDesign.Colors.backgroundPrimary, ANCHORDesign.Colors.backgroundSecondary, ANCHORDesign.Colors.backgroundPrimary]), initialLocation: (start: .leading, end: .leading))
        ) {
            VStack(alignment: .leading, spacing: size.contentSpacing) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(ANCHORDesign.Colors.backgroundSecondary)
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(ANCHORDesign.Colors.backgroundSecondary)
                    .frame(height: 60)
                
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ANCHORDesign.Colors.backgroundSecondary)
                        .frame(width: 60, height: 16)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ANCHORDesign.Colors.backgroundSecondary)
                        .frame(width: 80, height: 16)
                    Spacer()
                }
            }
        }
        .padding(cardPadding)
        .background(ANCHORDesign.Colors.backgroundCard)
        .cornerRadius(cardCornerRadius)
        .shadow(color: cardShadow.color, radius: cardShadow.radius, x: cardShadow.x, y: cardShadow.y)
    }
    
    @ViewBuilder
    private func errorView(_ error: ComponentError) -> some View {
        ErrorStateView(error: error) {
            loadingStateBinding?.wrappedValue.retry()
        }
        .padding(cardPadding)
        .background(ANCHORDesign.Colors.backgroundCard)
        .cornerRadius(cardCornerRadius)
    }
    
    // MARK: - Modifiers
    private var accessibilityModifier: some ViewModifier {
        AccessibilityModifier(
            label: accessibilityLabel ?? "Journal entry from \(formattedDate)",
            hint: accessibilityHint ?? "Double tap to view full entry",
            value: accessibilityValue ?? entry.body,
            actions: accessibilityActions ?? []
        )
    }
    
    private var keyboardNavigationModifier: some ViewModifier {
        KeyboardNavigationModifier(
            onUpArrow: enableKeyboardNavigation ? { /* Navigate up */ } : nil,
            onDownArrow: enableKeyboardNavigation ? { /* Navigate down */ } : nil,
            onEnter: enableKeyboardNavigation ? handleTap : nil,
            onEscape: nil
        )
    }
    
    @ViewBuilder
    private var contextMenuView: some View {
        ForEach(contextMenuActions.indices, id: \.self) { index in
            let action = contextMenuActions[index]
            
            if action.isDivider {
                Divider()
            } else {
                Button(action: {
                    if enableAnalytics {
                        ComponentAnalytics.shared.trackComponentInteraction(
                            component: "JournalEntryCard",
                            action: "context_menu_\(action.title.lowercased())"
                        )
                    }
                    action.handler()
                }) {
                    Label(action.title, systemImage: action.icon)
                }
                .disabled(!action.isEnabled)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupComponent() {
        if enableAnalytics {
            ComponentAnalytics.shared.trackComponentView(
                component: "JournalEntryCard",
                properties: [
                    "entry_id": entry.id.uuidString,
                    "style": String(describing: style),
                    "layout": String(describing: layout)
                ]
            )
        }
        
        if enableCache {
            loadCachedData()
        }
        
        if animateOnAppear {
            withAnimation(SpringAnimation.gentle.delay(Double.random(in: 0...0.3))) {
                hasAppeared = true
            }
        } else {
            hasAppeared = true
        }
    }
    
    private func cleanupComponent() {
        if enableCache {
            saveCachedData()
        }
    }
    
    private func loadCachedData() {
        let cacheKey = "journal_entry_\(entry.id.uuidString)"
        cachedImage = ComponentCache.shared.retrieve(forKey: cacheKey, as: UIImage.self)
    }
    
    private func saveCachedData() {
        if let cachedImage = cachedImage {
            let cacheKey = "journal_entry_\(entry.id.uuidString)"
            ComponentCache.shared.store(cachedImage, forKey: cacheKey)
        }
    }
    
    private func getScaleEffect() -> CGFloat {
        if isPressed && scaleOnPress {
            return 0.98
        } else if isHovered && hoverEffect {
            return 1.02
        } else if hasAppeared || !animateOnAppear {
            return 1.0
        } else {
            return 0.9
        }
    }
    
    private func handleTap() {
        if enableAnalytics {
            ComponentAnalytics.shared.trackComponentTap(
                component: "JournalEntryCard",
                properties: ["entry_id": entry.id.uuidString]
            )
        }
        
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        if scaleOnPress {
            withAnimation(SpringAnimation.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(SpringAnimation.quick) {
                    isPressed = false
                }
            }
        }
        
        if enableParticleEffects {
            showParticleEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showParticleEffect = false
            }
        }
        
        onTap?()
    }
    
    private func handleLongPress() {
        if enableAnalytics {
            ComponentAnalytics.shared.trackComponentLongPress(
                component: "JournalEntryCard",
                properties: ["entry_id": entry.id.uuidString]
            )
        }
        
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        onLongPress?()
    }
    
    private var defaultAccessibilityLabel: String {
        let title = entry.title ?? "Journal entry"
        let date = DateFormatter.localizedString(from: entry.date, dateStyle: .medium, timeStyle: .none)
        let mood = moodIcon.accessibilityLabel
        return "\(title), \(date), mood: \(mood)"
    }
}



// MARK: - Previews
struct JournalEntryCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = JournalEntryModel(
            id: UUID(),
            date: Date(),
            title: "A Great Day",
            body: "Today was an amazing day filled with positive thoughts and great experiences. I felt really good about my progress and the steps I'm taking towards recovery.",
            sentiment: 1,
            tags: ["positive", "recovery", "progress", "grateful"]
        )
        
        VStack(spacing: 20) {
            JournalEntryCard(entry: sampleEntry)
            
            JournalEntryCard(
                entry: sampleEntry,
                style: .detailed,
                size: .large,
                showWordCount: true,
                showAttachmentIndicator: true,
                animateOnAppear: true
            )
            
            JournalEntryCard(
                entry: sampleEntry,
                style: .minimal,
                size: .small,
                showChevron: false,
                maxTagsVisible: 2
            )
        }
        .padding()
        .previewDisplayName("Standard Card")
    }
}
