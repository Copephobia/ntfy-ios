//
//  NtfyTopic.swift
//  ntfy.sh
//
//  Created by Andrew Cope on 1/15/22.
//

import Foundation

class NtfyNotification: Identifiable, Decodable, Hashable {

    // Database Properties
    var id: String!
    var subscriptionId: Int64
    var timestamp: Int64
    var title: String
    var message: String
    var priority: Int
    var tags: [String]
    var attachment: NtfyAttachment?

    // Object Properties
    var emojiTags: [String] = []
    var nonEmojiTags: [String] = []

    init(id: String, subscriptionId: Int64, timestamp: Int64, title: String, message: String, priority: Int = 3, tags: [String] = [], attachment: NtfyAttachment?) {
        // Initialize values
        self.id = id
        self.subscriptionId = subscriptionId
        self.timestamp = timestamp
        self.title = title
        self.message = message
        self.priority = priority
        self.tags = tags
        self.attachment = attachment

        // Set notification tags
        self.setTags()
    }

    enum CodingKeys: String, CodingKey {
        case id, topic, time, title, message, priority, tags, attachment
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.subscriptionId = try Int64((Database.current.getSubscription(topic: container.decode(String.self, forKey: .topic))?.id)!)
        self.timestamp = try container.decode(Int64.self, forKey: .time)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.message = try container.decode(String.self, forKey: .message)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 3
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.attachment = try container.decodeIfPresent(NtfyAttachment.self, forKey: .attachment)

        self.setTags()
    }

    static func == (lhs: NtfyNotification, rhs: NtfyNotification) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func save() -> NtfyNotification? {
        return Database.current.addNotification(notification: self)
    }

    func setTags() {
        for tag in self.tags {
            if let emoji = EmojiManager.current.getEmojiByAlias(alias: tag) {
                self.emojiTags.append(emoji.getUnicode())
            } else if !tag.isEmpty {
                self.nonEmojiTags.append(tag)
            }
        }
    }

    func displayShortDateTime() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self.timestamp))
        let calendar = Calendar.current

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let dateFormatter = DateFormatter()

        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "h:mm a"
            dateFormatter.amSymbol = "AM"
            dateFormatter.pmSymbol = "PM"
        } else {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
        }

        return dateFormatter.string(from: date)
    }

    func timestampString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    func displayTitle() -> String {
        return self.title
    }

    func hasEmojiTags() -> Bool {
        return self.emojiTags.count > 0
    }

    func displayEmojiTags() -> String {
        var tagString = ""
        for tag in self.emojiTags {
            tagString += tag + " "
        }
        return tagString
    }

    func hasNonEmojiTags() -> Bool {
        return self.nonEmojiTags.count > 0
    }

    func displayNonEmojiTags() -> String {
        var tagString = ""
        for tag in self.nonEmojiTags {
                tagString += tag + ", "
        }
        if tagString.count > 0 {
            tagString = String(tagString.dropLast(2))
        }
        return tagString
    }
}
