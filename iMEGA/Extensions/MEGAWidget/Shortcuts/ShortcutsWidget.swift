import MEGAL10n
import MEGASwift
import SwiftUI
import WidgetKit

struct ShortcutsProvider: IntentTimelineProvider {

    typealias Intent = SelectShortcutIntent

    typealias Entry = ShortcutsWidgetEntry

    func placeholder(in context: Context) -> Entry {
        return Entry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts)
    }
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
    }
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let timeline = Timeline(entries: [Entry(date: Date(), shortcuts: shortcuts(for: configuration))], policy: .never)
        completion(timeline)
    }
    
    func shortcuts(for configuration: Intent) -> [ShortcutDetail] {
        var shortcuts = [ShortcutDetail]()
        configuration.shortcut?.forEach({ (intentShortcut) in
            shortcuts.append(shortcut(for: intentShortcut))
        })
        return shortcuts
    }
    
    func shortcut(for intent: IntentShortcut?) -> ShortcutDetail {
        
        guard let identifier = intent?.identifier else {
            return .defaultShortcut
        }
        
        switch identifier {
        case ShortcutDetail.uploadFile.link:
            return .uploadFile
        case ShortcutDetail.scanDocument.link:
            return.scanDocument
        case ShortcutDetail.startConversation.link:
            return .startConversation
        case ShortcutDetail.addContact.link:
            return .addContact
        default:
            return .defaultShortcut
        }
    }
}

struct ShortcutsWidget: Widget {
    let kind: String = MEGAShortcutsWidget

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: SelectShortcutIntent.self, provider: ShortcutsProvider()) { entry in
            ShortcutsWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.shortcuts)
        .description(Strings.Localizable.launchTheMEGAAppToPerformAnAction)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShortcutsWidgetEntry: TimelineEntry {
    let date: Date
    let shortcuts: [ShortcutDetail]
}

struct SmallShortcutWidgetView: View {
    let shortcut: ShortcutDetail
    
    var body: some View {
        
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Image(shortcut.imageName)
                    .frame(width: 56, height: 56, alignment: .leading)
                Spacer()
                Text(shortcut.title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            .padding(16)
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [shortcut.topBackgroundColor, shortcut.bottomBackgroundColor]), startPoint: .top, endPoint: .bottom))
        .widgetURL(URL(string: shortcut.link))
    }
}

struct ShortcutView: View {
    let shortcut: ShortcutDetail
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Image(shortcut.imageName)
                    .resizable()
                    .frame(width: 28, height: 28, alignment: .leading)
                    .padding([.leading, .trailing], 8)
                Text(shortcut.title)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .padding([.leading, .trailing], 8)
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [shortcut.topBackgroundColor, shortcut.bottomBackgroundColor]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(8)
    }
}

struct MediumShortcutsWidgetView: View {
    let shortcuts: [ShortcutDetail]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    if let firstShortcut = shortcuts[safe: 0], let url = URL(string: firstShortcut.link) {
                        Link(destination: url, label: {
                            ShortcutView(shortcut: firstShortcut)
                        })
                    }
                    if let secondShortcut = shortcuts[safe: 1], let url = URL(string: secondShortcut.link) {
                        Link(destination: url, label: {
                            ShortcutView(shortcut: secondShortcut)
                        })
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
                .frame(width: geometry.size.width, height: geometry.size.height/2)

                HStack(alignment: .top, spacing: 8) {
                    if let thirdShortcut = shortcuts[safe: 2], let url = URL(string: thirdShortcut.link) {
                        Link(destination: url, label: {
                            ShortcutView(shortcut: thirdShortcut)
                        })
                    }
                    if let fourthShortcut = shortcuts[safe: 3], let url = URL(string: fourthShortcut.link) {
                        Link(destination: url, label: {
                            ShortcutView(shortcut: fourthShortcut)
                        })
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))
                .frame(width: geometry.size.width, height: geometry.size.height/2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color("SecondaryBackground"))
        }
    }
}

struct ShortcutsWidgetView: View {
    var entry: ShortcutsProvider.Entry
    
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallShortcutWidgetView(shortcut: entry.shortcuts.first ?? ShortcutDetail.defaultShortcut)
        case .systemMedium:
            MediumShortcutsWidgetView(shortcuts: entry.shortcuts)
        default:
            EmptyView()
        }
    }
}

struct ShortcutsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsWidgetView(entry: ShortcutsWidgetEntry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        ShortcutsWidgetView(entry: ShortcutsWidgetEntry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
