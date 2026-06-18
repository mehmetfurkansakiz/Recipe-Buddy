import Foundation

enum LocalizedText {
    static func age(_ value: Int) -> String {
        count(value, oneKey: "age_count_one", otherKey: "age_count_other")
    }

    static func servings(_ value: Int) -> String {
        count(value, oneKey: "serving_count_one", otherKey: "serving_count_other")
    }

    static func recipes(_ value: Int) -> String {
        count(value, oneKey: "recipe_count_one", otherKey: "recipe_count_other")
    }

    static func shoppingItems(_ value: Int) -> String {
        count(value, oneKey: "shopping_item_count_one", otherKey: "shopping_item_count_other")
    }

    static func listItems(_ value: Int) -> String {
        count(value, oneKey: "list_item_count_one", otherKey: "list_item_count_other")
    }

    static func minutesShort(_ value: Int) -> String {
        String(format: NSLocalizedString("minute_short_count", comment: ""), value)
    }

    static func duration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return String(
                format: NSLocalizedString("duration_hours_minutes", comment: ""),
                hours,
                mins
            )
        } else if hours > 0 {
            return count(hours, oneKey: "hour_count_one", otherKey: "hour_count_other")
        } else {
            return count(mins, oneKey: "minute_count_one", otherKey: "minute_count_other")
        }
    }

    static func birthDate(_ date: Date?) -> String {
        guard let date else {
            return NSLocalizedString("Doğum tarihi: Belirtilmemiş", comment: "")
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .long
        formatter.timeStyle = .none

        return String(
            format: NSLocalizedString("birth_date_format", comment: ""),
            formatter.string(from: date)
        )
    }

    static func selectedDate(_ text: String) -> String {
        String(format: NSLocalizedString("selected_date_format", comment: ""), text)
    }

    static func ageLabel(_ value: Int) -> String {
        String(format: NSLocalizedString("age_label_format", comment: ""), value)
    }

    static func range(_ range: ClosedRange<Int>) -> String {
        String(
            format: NSLocalizedString("range_format", comment: ""),
            range.lowerBound,
            range.upperBound
        )
    }

    static func unit(_ value: String) -> String {
        NSLocalizedString("unit.\(value)", value: value, comment: "")
    }

    static func amount(_ amount: String, unit: String) -> String {
        "\(amount) \(Self.unit(unit))"
    }

    private static func count(_ value: Int, oneKey: String, otherKey: String) -> String {
        let key = value == 1 ? oneKey : otherKey
        return String(format: NSLocalizedString(key, comment: ""), value)
    }
}

