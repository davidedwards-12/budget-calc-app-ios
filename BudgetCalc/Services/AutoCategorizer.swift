import Foundation

/// Matches a transaction description against keyword rules and returns the best category name.
/// Rules are checked in order; the first match wins.
/// Income (positive amount) is always checked first.
enum AutoCategorizer {

    // MARK: - Public API

    /// Returns the category name that best fits the transaction, or nil if no rule matches.
    static func categorize(description: String, amount: Double) -> String? {
        let desc = description.lowercased()

        // Income — always check first for positive amounts
        if amount > 0 {
            for keyword in incomeKeywords where desc.contains(keyword) {
                return "Income"
            }
            // Payroll deposits from any employer (ECU shows "PERMOBIL INC ... PAYROLL")
            if desc.contains("payroll") || desc.contains("direct dep") { return "Income" }
            // Cashback / refunds that look like income — leave unmatched so user can decide
        }

        // Expenses — check each category in priority order
        for (categoryName, keywords) in rules {
            for keyword in keywords where desc.contains(keyword) {
                return categoryName
            }
        }

        return nil
    }

    // MARK: - Rules

    /// Ordered array so more-specific categories are checked before broad ones.
    private static let rules: [(String, [String])] = [
        ("Housing", housingKeywords),
        ("Utilities", utilityKeywords),
        ("Food & Dining", foodKeywords),
        ("Transportation", transportationKeywords),
        ("Health", healthKeywords),
        ("Entertainment", entertainmentKeywords),
        ("Shopping", shoppingKeywords),
    ]

    // MARK: - Keyword lists

    private static let incomeKeywords: [String] = [
        "payroll", "direct dep", "salary", "wages", "employer",
        "ach deposit", "ext deposit", "venmo - cashout", "cashout",
        "zelle", "deposit venmo",
    ]

    private static let housingKeywords: [String] = [
        "rent", "mortgage", "fogelman", "lease", "apartment", "hoa",
        "property", "real estate", "storage",
    ]

    private static let utilityKeywords: [String] = [
        "electric", "nes electric", "nes ", "water", "sewer",
        "gas company", "atmos", "comcast", "xfinity", "spectrum",
        "at&t", "verizon", "t-mobile", "tmobile", "internet",
        "phone bill", "utility", "waste",
    ]

    private static let foodKeywords: [String] = [
        // Fast food
        "mcdonald", "chick-fil-a", "chick fil a", "wendy", "sonic drive",
        "zaxby", "chipotle", "taco bell", "burger king", "kfc", "popeye",
        "subway", "domino", "pizza hut", "papa john", "little caesar",
        "panda express", "raising cane", "whataburger", "arby",
        "dairy queen", "hardee", "steak n shake",
        // Casual / sit-down
        "jack brown", "la hacienda", "mcalister", "applebee", "olive garden",
        "chili", "texas roadhouse", "cracker barrel", "ihop", "denny",
        "panera", "jason deli", "jim n nick", "o'charley",
        // Coffee / bakery
        "starbucks", "7 brew", "dutch bros", "coffee", "donut",
        "dunkin", "krispy kreme",
        // Groceries
        "kroger", "publix", "aldi", "whole foods", "harris teeter",
        "food city", "ingles", "winn-dixie", "trader joe",
        "walmart supercenter", "wm supercenter", "wal-mart",
        // Generic
        "restaurant", "bistro", "grill", "kitchen", "sushi",
        "tst*", "grubhub", "doordash", "ubereats", "instacart",
        "foxs pizza", "kilwins", "permobil cafe",
    ]

    private static let transportationKeywords: [String] = [
        "uber", "lyft", "taxi", "parkwhiz", "parkmobile", "lazgo",
        "parking", "toll", "sunpass", "ezpass", "gas", "shell",
        "exxon", "bp ", "chevron", "marathon", "pilot flying",
        "loves travel", "speedway", "circle k", "wawa",
        "auto zone", "o'reilly", "advance auto", "jiffy lube",
        "valvoline", "firestone", "goodyear", "pep boys",
        "delta air", "southwest air", "american air", "united air",
        "frontier air", "spirit air", "alaska air", "jetblue",
        "amtrak", "greyhound", "enterprise", "hertz", "avis",
    ]

    private static let healthKeywords: [String] = [
        "pharmacy", "cvs", "walgreen", "rite aid",
        "hospital", "clinic", "urgent care", "dental", "orthodon",
        "vision", "eye care", "optom", "lab corp", "quest diag",
        "doctor", "physician", "medical", "health", "fitness",
        "planet fitness", "gym", "ymca", "anytime fitness",
        "insurance", "united health", "cigna", "aetna", "humana",
        "blue cross", "bcbs",
    ]

    private static let entertainmentKeywords: [String] = [
        // Streaming
        "netflix", "spotify", "hulu", "disney", "apple.com/bill",
        "amazon prime", "peacock", "paramount", "hbo", "max ",
        "youtube", "twitch", "nintendo", "playstation", "xbox",
        "steam ", "apple music",
        // Sports / events
        "nashville mls", "ticketmaster", "eventbrite", "livenation",
        "stadium", "arena", "theater", "cinema", "amc ", "regal ",
        "fandango", "nayax amusem",
        // Other subscriptions
        "paypal *microsoft", "microsoft", "google ", "adobe",
        "dropbox", "icloud",
    ]

    private static let shoppingKeywords: [String] = [
        "amazon", "walmart.com", "target", "costco", "sam's club",
        "hobby lobby", "t.j. maxx", "tjmaxx", "tj maxx",
        "marshalls", "ross ", "burlington", "old navy", "gap ",
        "h&m", "zara", "forever 21", "american eagle", "hollister",
        "bath body", "victoria secret", "sephora", "ulta",
        "home depot", "lowe's", "lowes", "ikea", "bed bath",
        "best buy", "apple store", "floof", "box lunch",
        "opry mills", "paypal *",
    ]
}
