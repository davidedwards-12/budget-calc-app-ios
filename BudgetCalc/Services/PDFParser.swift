import Foundation
import PDFKit

struct ParsedTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let description: String
    let amount: Double
    var accountName: String = ""
}

struct ParsedAccount: Identifiable {
    let id = UUID()
    let name: String
    let transactions: [ParsedTransaction]
}

enum PDFParser {

    /// Primary entry point — returns transactions grouped by account.
    static func extractAccounts(from url: URL) -> [ParsedAccount] {
        guard let pdf = PDFDocument(url: url) else { return [] }
        var text = ""
        for i in 0..<pdf.pageCount {
            text += (pdf.page(at: i)?.string ?? "") + "\n"
        }
        return parseAccounts(from: text)
    }

    /// Flat list — convenience for single-account PDFs.
    static func extractTransactions(from url: URL) -> [ParsedTransaction] {
        extractAccounts(from: url).flatMap(\.transactions)
    }

    static func parseAccounts(from text: String) -> [ParsedAccount] {
        let joined = joinContinuationLines(text)
        var accountName = "Default Account"
        var buckets: [String: [ParsedTransaction]] = [:]
        var order: [String] = []

        for line in joined.components(separatedBy: .newlines) {
            // Detect account section headers (e.g. "Primary Share Account: XXXXXXX32372")
            if let detected = detectAccountName(in: line) {
                accountName = detected
                if buckets[accountName] == nil {
                    order.append(accountName)
                    buckets[accountName] = []
                }
                continue
            }

            if var t = parseLine(line) {
                t.accountName = accountName
                if buckets[accountName] == nil {
                    order.append(accountName)
                    buckets[accountName] = []
                }
                buckets[accountName]!.append(t)
            }
        }

        let result = order.compactMap { name -> ParsedAccount? in
            let txns = deduplicated(buckets[name] ?? [])
            guard !txns.isEmpty else { return nil }
            return ParsedAccount(name: name, transactions: txns)
        }

        // If nothing was sectioned, fall back to "Default Account"
        return result.isEmpty ? [] : result
    }

    static func parseTransactions(from text: String) -> [ParsedTransaction] {
        parseAccounts(from: text).flatMap(\.transactions)
    }

    // MARK: - Account detection

    /// Returns a cleaned account name if the line is a section header like
    /// "Primary Share Account: XXXXXXX32372" or "Beyond Free Checking Account: XXXXXXX32364 (Continued)".
    private static func detectAccountName(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().contains("account:"), !hasDatePrefix(trimmed) else { return nil }

        var name = trimmed
        // Remove account numbers (strings of X's followed by digits)
        name = name.replacingOccurrences(of: #"X+\d+"#, with: "", options: .regularExpression)
        // Remove "(Continued)"
        name = name.replacingOccurrences(of: #"\(Continued\)"#, with: "", options: [.regularExpression, .caseInsensitive])
        // Remove the colon
        name = name.replacingOccurrences(of: ":", with: "")
        // Collapse whitespace
        name = name.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return name.isEmpty ? nil : name
    }

    // MARK: - Line joining

    /// Appends lines that have no date prefix to the previous transaction line.
    /// This handles ECU's multi-line descriptions like "WALMART.COM...\nBENTONVILLE ARUS".
    private static func joinContinuationLines(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { result.append(""); continue }

            if hasDatePrefix(trimmed) {
                result.append(trimmed)
            } else if !result.isEmpty && !isNonTransactionLine(trimmed) {
                let prev = result.removeLast()
                result.append(prev + " " + trimmed)
            } else {
                result.append(trimmed)
            }
        }
        return result.joined(separator: "\n")
    }

    private static func hasDatePrefix(_ line: String) -> Bool {
        // MM-DD or MM/DD at start of line (ECU uses dashes, others use slashes)
        return line.range(of: #"^\d{1,2}[-/]\d{1,2}\b"#, options: .regularExpression) != nil
    }

    // MARK: - Line parsing

    private static func parseLine(_ raw: String) -> ParsedTransaction? {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard line.count > 8 else { return nil }
        guard !isNonTransactionLine(line) else { return nil }

        guard let dateRange = findFirstDateRange(in: line),
              let date = parseDate(String(line[dateRange])) else { return nil }

        let allAmounts = findAllAmounts(in: line)
        guard !allAmounts.isEmpty else { return nil }

        // ECU format: each line ends with [transaction_amount, running_balance]
        // Generic format: each line ends with [transaction_amount]
        // Rule: if 2+ amounts, the second-to-last is the transaction; last is the balance.
        let txAmount: Double
        if allAmounts.count >= 2 {
            txAmount = allAmounts[allAmounts.count - 2]
        } else {
            txAmount = allAmounts[0]
        }

        guard abs(txAmount) > 0.009 else { return nil }

        // Description = text after the date, with all amounts stripped
        let afterDate = String(line[dateRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        let description = stripAllAmounts(from: afterDate)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        guard description.count > 1 else { return nil }

        return ParsedTransaction(date: date, description: description, amount: txAmount)
    }

    // MARK: - Date helpers

    private static func findFirstDateRange(in line: String) -> Range<String.Index>? {
        // Order matters: try longer/more-specific patterns first
        let patterns = [
            #"\b\d{1,2}-\d{1,2}-\d{4}\b"#,  // MM-DD-YYYY
            #"\b\d{1,2}/\d{1,2}/\d{4}\b"#,  // MM/DD/YYYY
            #"\b\d{1,2}-\d{1,2}-\d{2}\b"#,  // MM-DD-YY
            #"\b\d{1,2}/\d{1,2}/\d{2}\b"#,  // MM/DD/YY
            #"\b\d{1,2}-\d{1,2}\b"#,         // MM-DD  (ECU)
            #"\b\d{1,2}/\d{1,2}\b"#,         // MM/DD
        ]
        for p in patterns {
            if let r = line.range(of: p, options: .regularExpression) { return r }
        }
        return nil
    }

    private static func parseDate(_ s: String) -> Date? {
        // Normalize dashes → slashes so one set of formatters handles both
        let normalized = s.replacingOccurrences(of: "-", with: "/")
        let formats = ["MM/dd/yyyy", "MM/dd/yy", "MM/dd"]
        let currentYear = Calendar.current.component(.year, from: Date())
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            f.dateFormat = fmt
            if var d = f.date(from: normalized) {
                if fmt == "MM/dd" {
                    var c = Calendar.current.dateComponents([.month, .day], from: d)
                    c.year = currentYear
                    d = Calendar.current.date(from: c) ?? d
                    // If the date is in the future it belongs to the previous year
                    // (e.g. importing a December 2025 statement in 2026)
                    if d > Date() {
                        c.year = currentYear - 1
                        d = Calendar.current.date(from: c) ?? d
                    }
                }
                return d
            }
        }
        return nil
    }

    // MARK: - Amount helpers

    /// Returns all monetary amounts found in a line, in order.
    private static func findAllAmounts(in line: String) -> [Double] {
        let pattern = #"[\(\-]?\$?[\d,]+\.\d{2}\)?"#
        var amounts: [Double] = []
        var range = line.startIndex..<line.endIndex
        while let r = line.range(of: pattern, options: .regularExpression, range: range) {
            if let v = parseAmount(String(line[r])) {
                amounts.append(v)
            }
            guard r.upperBound < line.endIndex else { break }
            range = r.upperBound..<line.endIndex
        }
        return amounts
    }

    private static func parseAmount(_ s: String) -> Double? {
        let negative = s.hasPrefix("(") && s.hasSuffix(")")
        let clean = s
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let v = Double(clean) else { return nil }
        return negative ? -abs(v) : v
    }

    /// Removes all monetary amounts from a string (used to isolate the description).
    private static func stripAllAmounts(from text: String) -> String {
        text.replacingOccurrences(
            of: #"\s*[\(\-]?\$?[\d,]+\.\d{2}\)?\s*"#,
            with: " ",
            options: .regularExpression
        )
    }

    // MARK: - Filters

    private static func isNonTransactionLine(_ line: String) -> Bool {
        let lower = line.lowercased()

        // ECU section / header lines
        let sectionPhrases = [
            "account:", "member number", "statement date", "page ",
            "dividend rate summary", "detail of transactions", "summary of accounts",
            "want your statement", "annual percentage", "total number of days",
            "amount of dividends", "deposits, dividends", "withdrawals, fees",
            "total overdraft", "total returned", "total deposits", "total withdrawals",
            "total fees", "total number of checks", "total year-to-date",
            "total for this period", "starting balance", "ending balance",
        ]
        if sectionPhrases.contains(where: { lower.contains($0) }) { return true }

        // Column header rows (short lines that are only header words)
        let headerOnlyWords = ["balance", "date", "description", "amount",
                               "deposit", "withdrawal", "trans", "eff"]
        let words = lower.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if !words.isEmpty && words.allSatisfy({ headerOnlyWords.contains($0) }) { return true }

        return false
    }

    private static func deduplicated(_ list: [ParsedTransaction]) -> [ParsedTransaction] {
        var seen = Set<String>()
        return list.filter { t in
            let key = "\(Int(t.date.timeIntervalSince1970))-\(t.amount)-\(t.description.prefix(15))"
            return seen.insert(key).inserted
        }
    }
}
